import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PaidMessage } from '../entities/paid-message.entity';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { StreamComment } from '../entities/stream-comment.entity';
import { WalletService } from '../wallet/wallet.service';
import { TransactionType } from '../common/enums';
import { SendPaidMessageDto } from './paid-messages.dto';
import { StreamsGateway } from '../gateway/streams.gateway';
import { AuthService } from '../auth/auth.service';

@Injectable()
export class PaidMessagesService {
  constructor(
    @InjectRepository(PaidMessage) private paidRepo: Repository<PaidMessage>,
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Stream) private streamsRepo: Repository<Stream>,
    @InjectRepository(StreamComment) private commentsRepo: Repository<StreamComment>,
    private walletService: WalletService,
    private gateway: StreamsGateway,
    private authService: AuthService,
  ) {}

  async send(senderId: string, dto: SendPaidMessageDto) {
    const receiver = await this.usersRepo.findOne({ where: { id: dto.receiverId } });
    if (!receiver) throw new NotFoundException('Receiver not found');

    const debit = await this.walletService.debit(
      senderId,
      dto.amount,
      TransactionType.PAID_MESSAGE,
      dto.idempotencyKey,
      {
        counterpartyId: receiver.id,
        counterpartyName: receiver.displayName,
        description: `Paid message: ${dto.text.slice(0, 40)}`,
      },
    );

    if (!debit.duplicate) {
      await this.walletService.creditCreator(
        receiver.id,
        dto.amount,
        TransactionType.PAID_MESSAGE,
        dto.idempotencyKey,
        {
          counterpartyId: senderId,
          description: 'Paid message received',
        },
      );
    }

    let paid = await this.paidRepo.findOne({
      where: { transactionId: debit.transaction.id },
    });

    if (!paid) {
      paid = this.paidRepo.create({
        senderId,
        receiverId: receiver.id,
        streamId: dto.streamId,
        postId: dto.postId,
        text: dto.text,
        amount: dto.amount,
        transactionId: debit.transaction.id,
      });
      await this.paidRepo.save(paid);
    }

    const sender = await this.usersRepo.findOne({ where: { id: senderId } });

    if (dto.streamId) {
      const stream = await this.streamsRepo.findOne({ where: { id: dto.streamId } });
      if (stream && sender) {
        const comment = this.commentsRepo.create({
          streamId: dto.streamId,
          userId: senderId,
          text: `💎 ${dto.text}`,
          isAi: false,
          isGift: false,
        });
        await this.commentsRepo.save(comment);

        const payload = {
          id: comment.id,
          streamId: dto.streamId,
          user: this.authService.toPublicUser(sender),
          text: comment.text,
          createdAt: comment.createdAt,
          isAi: false,
          isGift: false,
          isPaid: true,
          paidAmount: dto.amount,
        };
        this.gateway.emitPaidMessage(dto.streamId, payload);
        this.gateway.emitComment(dto.streamId, payload);
      }
    }

    return {
      id: paid.id,
      text: paid.text,
      amount: Number(paid.amount),
      receiver: { id: receiver.id, displayName: receiver.displayName },
    };
  }

  async getForCreator(creatorId: string) {
    const messages = await this.paidRepo.find({
      where: { receiverId: creatorId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
    return messages.map((m) => ({
      id: m.id,
      text: m.text,
      amount: Number(m.amount),
      streamId: m.streamId,
      createdAt: m.createdAt,
    }));
  }
}
