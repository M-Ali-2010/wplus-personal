import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Donation } from '../entities/donation.entity';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { WalletService } from '../wallet/wallet.service';
import { TransactionType } from '../common/enums';
import { CreateDonationDto } from './donations.dto';
import { StreamsGateway } from '../gateway/streams.gateway';

@Injectable()
export class DonationsService {
  constructor(
    @InjectRepository(Donation) private donationsRepo: Repository<Donation>,
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Stream) private streamsRepo: Repository<Stream>,
    private walletService: WalletService,
    private streamsGateway: StreamsGateway,
  ) {}

  async create(senderId: string, dto: CreateDonationDto) {
    const receiver = await this.usersRepo.findOne({ where: { id: dto.receiverId } });
    if (!receiver) throw new NotFoundException('Receiver not found');

    const debit = await this.walletService.debit(
      senderId,
      dto.amount,
      TransactionType.DONATION,
      dto.idempotencyKey,
      {
        counterpartyId: receiver.id,
        counterpartyName: receiver.displayName,
        description: dto.message ?? 'Support donation',
      },
    );

    if (!debit.duplicate) {
      await this.walletService.creditCreator(
        receiver.id,
        dto.amount,
        TransactionType.DONATION,
        dto.idempotencyKey,
        {
          counterpartyId: senderId,
          description: dto.message ?? 'Donation received',
        },
      );
    }

    let donation = await this.donationsRepo.findOne({
      where: { transactionId: debit.transaction.id },
    });

    if (!donation) {
      donation = this.donationsRepo.create({
        senderId,
        receiverId: receiver.id,
        postId: dto.postId,
        streamId: dto.streamId,
        amount: dto.amount,
        message: dto.message,
        transactionId: debit.transaction.id,
      });
      await this.donationsRepo.save(donation);
    }

    if (dto.streamId) {
      const stream = await this.streamsRepo.findOne({ where: { id: dto.streamId } });
      if (stream) {
        stream.donationsTotal = Number(stream.donationsTotal) + dto.amount;
        await this.streamsRepo.save(stream);
      }

      const sender = await this.usersRepo.findOne({ where: { id: senderId } });
      this.streamsGateway.emitDonation(dto.streamId, {
        streamId: dto.streamId,
        amount: dto.amount,
        senderId,
        senderName: sender?.displayName ?? 'User',
        receiverId: receiver.id,
        message: dto.message,
      });
    }

    return {
      id: donation.id,
      amount: Number(donation.amount),
      receiver: { id: receiver.id, displayName: receiver.displayName },
      message: donation.message,
    };
  }
}
