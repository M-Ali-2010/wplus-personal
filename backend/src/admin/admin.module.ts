import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { Transaction } from '../entities/transaction.entity';
import { GiftTransaction } from '../entities/gift-transaction.entity';
import { Donation } from '../entities/donation.entity';
import { PaidMessage } from '../entities/paid-message.entity';
import { Gift } from '../entities/gift.entity';
import { AuthModule } from '../auth/auth.module';
import { AdminController } from './admin.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Stream,
      Transaction,
      GiftTransaction,
      Donation,
      PaidMessage,
      Gift,
    ]),
    AuthModule,
  ],
  controllers: [AdminController],
})
export class AdminModule {}
