import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Transaction } from '../entities/transaction.entity';
import { Stream } from '../entities/stream.entity';
import { GiftTransaction } from '../entities/gift-transaction.entity';
import { Donation } from '../entities/donation.entity';
import { PaidMessage } from '../entities/paid-message.entity';
import { TransactionStatus, TransactionType } from '../common/enums';

@Injectable()
export class DashboardService {
  constructor(
    @InjectRepository(Transaction) private txRepo: Repository<Transaction>,
    @InjectRepository(Stream) private streamsRepo: Repository<Stream>,
    @InjectRepository(GiftTransaction) private giftTxRepo: Repository<GiftTransaction>,
    @InjectRepository(Donation) private donationsRepo: Repository<Donation>,
    @InjectRepository(PaidMessage) private paidRepo: Repository<PaidMessage>,
  ) {}

  async getCreatorDashboard(creatorId: string) {
    const incomeTxs = await this.txRepo.find({
      where: {
        userId: creatorId,
        status: TransactionStatus.COMPLETED,
      },
    });

    const revenue = incomeTxs
      .filter((t) => Number(t.amount) > 0)
      .reduce((sum, t) => sum + Number(t.amount), 0);

    const gifts = await this.giftTxRepo.find({ where: { receiverId: creatorId } });
    const giftsTotal = gifts.reduce((s, g) => s + Number(g.amount), 0);

    const donations = await this.donationsRepo.find({ where: { receiverId: creatorId } });
    const donationsTotal = donations.reduce((s, d) => s + Number(d.amount), 0);

    const paidMessages = await this.paidRepo.find({ where: { receiverId: creatorId } });
    const paidMessagesTotal = paidMessages.reduce((s, m) => s + Number(m.amount), 0);

    const streams = await this.streamsRepo.find({ where: { creatorId } });
    const liveStreams = streams.filter((s) => s.status === 'live').length;

    return {
      revenue: { total: revenue, currency: 'W' },
      gifts: { count: gifts.length, total: giftsTotal },
      donations: { count: donations.length, total: donationsTotal },
      paidMessages: { count: paidMessages.length, total: paidMessagesTotal },
      streams: {
        total: streams.length,
        live: liveStreams,
        totalViewers: streams.reduce((s, st) => s + st.peakViewers, 0),
      },
      pendingBalance: 0,
      availableForPayout: revenue * 0.85,
    };
  }
}
