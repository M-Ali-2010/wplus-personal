import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Transaction } from '../entities/transaction.entity';
import { Stream } from '../entities/stream.entity';
import { GiftTransaction } from '../entities/gift-transaction.entity';
import { Donation } from '../entities/donation.entity';
import { PaidMessage } from '../entities/paid-message.entity';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Transaction, Stream, GiftTransaction, Donation, PaidMessage])],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}
