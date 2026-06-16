import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription } from '../entities/subscription.entity';
import { PremiumPost } from '../entities/premium-post.entity';
import { User } from '../entities/user.entity';
import { WalletService } from '../wallet/wallet.service';
import { TransactionType } from '../common/enums';
import { CreatePremiumPostDto, SubscribeDto } from './subscriptions.dto';
import { AuthService } from '../auth/auth.service';

@Injectable()
export class SubscriptionsService {
  private readonly monthlyPrice = 99;

  constructor(
    @InjectRepository(Subscription) private subsRepo: Repository<Subscription>,
    @InjectRepository(PremiumPost) private postsRepo: Repository<PremiumPost>,
    @InjectRepository(User) private usersRepo: Repository<User>,
    private walletService: WalletService,
    private authService: AuthService,
  ) {}

  async subscribe(subscriberId: string, dto: SubscribeDto) {
    if (subscriberId === dto.creatorId) {
      throw new BadRequestException('Cannot subscribe to yourself');
    }

    const creator = await this.usersRepo.findOne({ where: { id: dto.creatorId } });
    if (!creator) throw new NotFoundException('Creator not found');

    const existing = await this.subsRepo.findOne({
      where: { subscriberId, creatorId: dto.creatorId, isActive: true },
    });
    if (existing && existing.expiresAt > new Date()) {
      return { subscription: this.toPublicSub(existing), duplicate: true };
    }

    const debit = await this.walletService.debit(
      subscriberId,
      this.monthlyPrice,
      TransactionType.SUBSCRIPTION,
      dto.idempotencyKey,
      {
        counterpartyId: creator.id,
        counterpartyName: creator.displayName,
        description: `Subscribe to ${creator.displayName}`,
      },
    );

    if (!debit.duplicate) {
      await this.walletService.creditCreator(
        creator.id,
        this.monthlyPrice,
        TransactionType.SUBSCRIPTION,
        dto.idempotencyKey,
        { counterpartyId: subscriberId, description: 'New subscriber' },
      );
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    let sub = await this.subsRepo.findOne({
      where: { transactionId: debit.transaction.id },
    });

    if (!sub) {
      sub = this.subsRepo.create({
        subscriberId,
        creatorId: creator.id,
        tier: dto.tier ?? 'premium',
        price: this.monthlyPrice,
        expiresAt,
        isActive: true,
        transactionId: debit.transaction.id,
      });
      await this.subsRepo.save(sub);
    }

    return { subscription: this.toPublicSub(sub), duplicate: false };
  }

  async getMySubscriptions(userId: string) {
    const subs = await this.subsRepo.find({
      where: { subscriberId: userId, isActive: true },
      order: { createdAt: 'DESC' },
    });
    return subs.filter((s) => s.expiresAt > new Date()).map((s) => this.toPublicSub(s));
  }

  async isSubscribed(subscriberId: string, creatorId: string) {
    const sub = await this.subsRepo.findOne({
      where: { subscriberId, creatorId, isActive: true },
    });
    return !!(sub && sub.expiresAt > new Date());
  }

  async createPremiumPost(creatorId: string, dto: CreatePremiumPostDto) {
    const post = this.postsRepo.create({
      creatorId,
      title: dto.title,
      content: dto.content,
      price: dto.price,
      isPremium: dto.price > 0,
      thumbnailUrl: dto.thumbnailUrl,
    });
    await this.postsRepo.save(post);
    return this.toPublicPost(post, false);
  }

  async getPremiumPosts(creatorId?: string) {
    const where = creatorId ? { creatorId } : {};
    const posts = await this.postsRepo.find({ where, order: { createdAt: 'DESC' } });
    return posts.map((p) => this.toPublicPost(p, true));
  }

  async getPremiumPost(postId: string, userId: string) {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');

    const hasAccess =
      post.creatorId === userId ||
      !post.isPremium ||
      (await this.isSubscribed(userId, post.creatorId));

    return this.toPublicPost(post, !hasAccess);
  }

  async purchasePost(userId: string, postId: string, idempotencyKey: string) {
    const post = await this.postsRepo.findOne({ where: { id: postId } });
    if (!post) throw new NotFoundException('Post not found');
    if (!post.isPremium || post.price <= 0) {
      throw new BadRequestException('Post is not premium');
    }
    if (post.creatorId === userId) throw new ForbiddenException('Own post');

    const debit = await this.walletService.debit(
      userId,
      Number(post.price),
      TransactionType.PURCHASE,
      idempotencyKey,
      {
        counterpartyId: post.creatorId,
        referenceId: post.id,
        description: `Premium: ${post.title}`,
      },
    );

    if (!debit.duplicate) {
      await this.walletService.creditCreator(
        post.creatorId,
        Number(post.price),
        TransactionType.PURCHASE,
        idempotencyKey,
        { counterpartyId: userId, referenceId: post.id, description: 'Premium content sale' },
      );
    }

    return this.toPublicPost(post, false);
  }

  private toPublicSub(sub: Subscription) {
    return {
      id: sub.id,
      creatorId: sub.creatorId,
      tier: sub.tier,
      price: Number(sub.price),
      expiresAt: sub.expiresAt,
      isActive: sub.isActive && sub.expiresAt > new Date(),
    };
  }

  private toPublicPost(post: PremiumPost, locked: boolean) {
    return {
      id: post.id,
      creatorId: post.creatorId,
      title: post.title,
      content: locked ? null : post.content,
      price: Number(post.price),
      isPremium: post.isPremium,
      isLocked: locked,
      thumbnailUrl: post.thumbnailUrl,
      createdAt: post.createdAt,
    };
  }
}
