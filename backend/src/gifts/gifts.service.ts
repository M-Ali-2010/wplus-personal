import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Gift } from '../entities/gift.entity';
import { GiftTransaction as GiftTxEntity } from '../entities/gift-transaction.entity';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { WalletService } from '../wallet/wallet.service';
import { TransactionType } from '../common/enums';
import { SendGiftDto } from './gifts.dto';
import { StreamsGateway } from '../gateway/streams.gateway';

@Injectable()
export class GiftsService {
  constructor(
    @InjectRepository(Gift) private giftsRepo: Repository<Gift>,
    @InjectRepository(GiftTxEntity) private giftTxRepo: Repository<GiftTxEntity>,
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Stream) private streamsRepo: Repository<Stream>,
    private walletService: WalletService,
    private streamsGateway: StreamsGateway,
  ) {}

  async getCatalog() {
    const gifts = await this.giftsRepo.find({
      where: { isActive: true },
      order: { sortOrder: 'ASC', price: 'ASC' },
    });
    return gifts.map((g) => ({
      id: g.id,
      title: g.title,
      category: g.categorySlug,
      price: Number(g.price),
      assetType: g.assetType,
      assetUrl: g.assetUrl,
      emoji: g.emoji,
    }));
  }

  async sendGift(senderId: string, dto: SendGiftDto) {
    const gift = await this.giftsRepo.findOne({ where: { id: dto.giftId, isActive: true } });
    if (!gift) throw new NotFoundException('Gift not found');

    const receiver = await this.usersRepo.findOne({ where: { id: dto.receiverId } });
    if (!receiver) throw new NotFoundException('Receiver not found');

    const price = Number(gift.price) * (dto.quantity ?? 1);
    const idempotencyKey = dto.idempotencyKey;

    const debitResult = await this.walletService.debit(senderId, price, TransactionType.GIFT, idempotencyKey, {
      counterpartyId: receiver.id,
      counterpartyName: receiver.displayName,
      referenceId: gift.id,
      description: `${gift.title}${dto.quantity && dto.quantity > 1 ? ` x${dto.quantity}` : ''}`,
    });

    if (debitResult.duplicate) {
      const existing = await this.giftTxRepo.findOne({
        where: { transactionId: debitResult.transaction.id },
      });
      if (existing) return this.buildGiftResponse(existing, gift, receiver, dto);
    }

    await this.walletService.creditCreator(
      receiver.id,
      price,
      TransactionType.GIFT,
      idempotencyKey,
      {
        counterpartyId: senderId,
        referenceId: gift.id,
        description: `Gift: ${gift.title}`,
      },
    );

    const giftTx = this.giftTxRepo.create({
      giftId: gift.id,
      senderId,
      receiverId: receiver.id,
      streamId: dto.streamId,
      amount: price,
      transactionId: debitResult.transaction.id,
    });
    await this.giftTxRepo.save(giftTx);

    if (dto.streamId) {
      const stream = await this.streamsRepo.findOne({ where: { id: dto.streamId } });
      if (stream) {
        stream.giftsTotal = Number(stream.giftsTotal) + price;
        await this.streamsRepo.save(stream);
      }

      const sender = await this.usersRepo.findOne({ where: { id: senderId } });
      this.streamsGateway.emitGift(dto.streamId, {
        streamId: dto.streamId,
        giftId: gift.id,
        giftTitle: gift.title,
        giftEmoji: gift.emoji,
        senderId,
        senderName: sender?.displayName ?? 'User',
        receiverId: receiver.id,
        amount: price,
        quantity: dto.quantity ?? 1,
      });
    }

    return this.buildGiftResponse(giftTx, gift, receiver, dto);
  }

  private buildGiftResponse(
    giftTx: GiftTxEntity,
    gift: Gift,
    receiver: User,
    dto: SendGiftDto,
  ) {
    return {
      id: giftTx.id,
      gift: {
        id: gift.id,
        title: gift.title,
        emoji: gift.emoji,
        price: Number(gift.price),
      },
      receiver: { id: receiver.id, displayName: receiver.displayName },
      amount: Number(giftTx.amount),
      streamId: dto.streamId,
    };
  }
}
