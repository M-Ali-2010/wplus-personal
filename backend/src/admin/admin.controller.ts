import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { Transaction } from '../entities/transaction.entity';
import { GiftTransaction } from '../entities/gift-transaction.entity';
import { Donation } from '../entities/donation.entity';
import { PaidMessage } from '../entities/paid-message.entity';
import { Gift } from '../entities/gift.entity';
import { StreamStatus, UserRole } from '../common/enums';
import { AuthService } from '../auth/auth.service';

@Controller('api/admin')
@UseGuards(JwtAuthGuard)
export class AdminController {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Stream) private streamsRepo: Repository<Stream>,
    @InjectRepository(Transaction) private txRepo: Repository<Transaction>,
    @InjectRepository(GiftTransaction) private giftTxRepo: Repository<GiftTransaction>,
    @InjectRepository(Donation) private donationsRepo: Repository<Donation>,
    @InjectRepository(PaidMessage) private paidRepo: Repository<PaidMessage>,
    @InjectRepository(Gift) private giftsRepo: Repository<Gift>,
    private authService: AuthService,
  ) {}

  private assertAdmin(user: User) {
    if (user.role !== UserRole.ADMIN && user.role !== UserRole.SUPER_ADMIN) {
      throw new ForbiddenException('Admin access required');
    }
  }

  @Get('stats')
  async stats(@Req() req: { user: User }) {
    this.assertAdmin(req.user);
    const [users, streams, txs, gifts, donations, paidMessages, liveStreams, creators] =
      await Promise.all([
        this.usersRepo.count(),
        this.streamsRepo.count(),
        this.txRepo.count(),
        this.giftTxRepo.count(),
        this.donationsRepo.count(),
        this.paidRepo.count(),
        this.streamsRepo.count({ where: { status: StreamStatus.LIVE } }),
        this.usersRepo.count({ where: { role: UserRole.CREATOR } }),
      ]);

    const totalRevenue = await this.txRepo
      .createQueryBuilder('tx')
      .select('SUM(tx.amount)', 'total')
      .where('tx.amount > 0')
      .getRawOne<{ total: string }>();

    return {
      users,
      creators,
      streams,
      liveStreams,
      transactions: txs,
      gifts,
      donations,
      paidMessages,
      totalRevenue: Math.round(Number(totalRevenue?.total ?? 0)),
    };
  }

  @Get('users')
  async users(@Req() req: { user: User }) {
    this.assertAdmin(req.user);
    const list = await this.usersRepo.find({ order: { createdAt: 'DESC' }, take: 200 });
    return list.map((u) => ({
      ...this.authService.toPublicUser(u),
      email: u.email,
      createdAt: u.createdAt,
      isBanned: (u as any).isBanned ?? false,
    }));
  }

  @Patch('users/:id/verify')
  async verifyUser(@Req() req: { user: User }, @Param('id') id: string) {
    this.assertAdmin(req.user);
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new ForbiddenException('User not found');
    user.isVerified = !user.isVerified;
    await this.usersRepo.save(user);
    return { id, isVerified: user.isVerified };
  }

  @Post('users/:id/ban')
  async banUser(
    @Req() req: { user: User },
    @Param('id') id: string,
    @Body() body: { reason?: string },
  ) {
    this.assertAdmin(req.user);
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new ForbiddenException('User not found');
    (user as any).isBanned = true;
    await this.usersRepo.save(user);
    return { id, banned: true, reason: body.reason };
  }

  @Post('users/:id/unban')
  async unbanUser(@Req() req: { user: User }, @Param('id') id: string) {
    this.assertAdmin(req.user);
    const user = await this.usersRepo.findOne({ where: { id } });
    if (!user) throw new ForbiddenException('User not found');
    (user as any).isBanned = false;
    await this.usersRepo.save(user);
    return { id, banned: false };
  }

  @Get('streams')
  async streams(@Req() req: { user: User }) {
    this.assertAdmin(req.user);
    const list = await this.streamsRepo.find({
      relations: ['creator'],
      order: { createdAt: 'DESC' },
      take: 100,
    });
    return list.map((s) => ({
      id: s.id,
      title: s.title,
      status: s.status,
      viewerCount: s.viewerCount,
      giftsTotal: Number(s.giftsTotal),
      donationsTotal: Number(s.donationsTotal),
      startedAt: s.startedAt,
      createdAt: s.createdAt,
      creator: s.creator ? this.authService.toPublicUser(s.creator) : { id: s.creatorId },
    }));
  }

  @Post('streams/:id/end')
  async endStream(@Req() req: { user: User }, @Param('id') id: string) {
    this.assertAdmin(req.user);
    const stream = await this.streamsRepo.findOne({ where: { id } });
    if (!stream) throw new ForbiddenException('Stream not found');
    stream.status = StreamStatus.ENDED;
    stream.endedAt = new Date();
    await this.streamsRepo.save(stream);
    return { id, status: StreamStatus.ENDED };
  }

  @Get('transactions')
  async transactions(@Req() req: { user: User }) {
    this.assertAdmin(req.user);
    const list = await this.txRepo.find({
      order: { createdAt: 'DESC' },
      take: 200,
    });
    return list;
  }

  @Get('donations')
  async donations(@Req() req: { user: User }) {
    this.assertAdmin(req.user);
    const list = await this.donationsRepo.find({
      order: { createdAt: 'DESC' },
      take: 100,
    });
    const userIds = [...new Set([...list.map((d) => d.senderId), ...list.map((d) => d.receiverId)])];
    const users = userIds.length
      ? await this.usersRepo.findByIds(userIds)
      : [];
    const userMap = Object.fromEntries(users.map((u) => [u.id, this.authService.toPublicUser(u)]));
    return list.map((d) => ({
      ...d,
      amount: Number(d.amount),
      sender: userMap[d.senderId] ?? { id: d.senderId },
      receiver: userMap[d.receiverId] ?? { id: d.receiverId },
    }));
  }

  @Get('gifts')
  async gifts(@Req() req: { user: User }) {
    this.assertAdmin(req.user);
    return this.giftsRepo.find({ order: { price: 'ASC' } });
  }

  @Get('paid-messages')
  async paidMessages(@Req() req: { user: User }) {
    this.assertAdmin(req.user);
    const list = await this.paidRepo.find({
      order: { createdAt: 'DESC' },
      take: 100,
    });
    const userIds = [...new Set([...list.map((m) => m.senderId), ...list.map((m) => m.receiverId)])];
    const users = userIds.length
      ? await this.usersRepo.findByIds(userIds)
      : [];
    const userMap = Object.fromEntries(users.map((u) => [u.id, this.authService.toPublicUser(u)]));
    return list.map((m) => ({
      ...m,
      amount: Number(m.amount),
      sender: userMap[m.senderId] ?? { id: m.senderId },
      receiver: userMap[m.receiverId] ?? { id: m.receiverId },
    }));
  }
}
