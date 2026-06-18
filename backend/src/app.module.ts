import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { WalletModule } from './wallet/wallet.module';
import { GiftsModule } from './gifts/gifts.module';
import { DonationsModule } from './donations/donations.module';
import { StreamsModule } from './streams/streams.module';
import { BattlesModule } from './battles/battles.module';
import { AiModule } from './ai/ai.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { GatewayModule } from './gateway/gateway.module';
import { User } from './entities/user.entity';
import { Wallet } from './entities/wallet.entity';
import { Transaction } from './entities/transaction.entity';
import { Gift, GiftCategory } from './entities/gift.entity';
import { GiftTransaction } from './entities/gift-transaction.entity';
import { Stream } from './entities/stream.entity';
import { StreamComment } from './entities/stream-comment.entity';
import { Donation } from './entities/donation.entity';
import { AiOpponent, Battle } from './entities/battle.entity';
import { PaidMessage } from './entities/paid-message.entity';
import { Subscription } from './entities/subscription.entity';
import { PremiumPost } from './entities/premium-post.entity';
import { PaidMessagesModule } from './paid-messages/paid-messages.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { AdminModule } from './admin/admin.module';
import { MarketplaceModule } from './marketplace/marketplace.module';
import { Job } from './entities/job.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const dbUrl = config.get<string>('DATABASE_URL');
        const base = {
          entities: [
            User, Wallet, Transaction, Gift, GiftCategory, GiftTransaction,
            Stream, StreamComment, Donation, AiOpponent, Battle, PaidMessage,
            Subscription, PremiumPost, Job,
          ],
          synchronize: true,
          logging: config.get('NODE_ENV') === 'development',
        };
        if (dbUrl) {
          return { type: 'postgres' as const, url: dbUrl, ssl: { rejectUnauthorized: false }, ...base };
        }
        return {
          type: 'postgres' as const,
          host: config.get<string>('DATABASE_HOST', 'localhost'),
          port: config.get<number>('DATABASE_PORT', 5432),
          username: config.get<string>('DATABASE_USER', 'wplus'),
          password: config.get<string>('DATABASE_PASSWORD', 'wplus_secret'),
          database: config.get<string>('DATABASE_NAME', 'wplus'),
          ...base,
        };
      },
    }),
    AuthModule,
    WalletModule,
    GiftsModule,
    DonationsModule,
    StreamsModule,
    BattlesModule,
    AiModule,
    DashboardModule,
    GatewayModule,
    PaidMessagesModule,
    SubscriptionsModule,
    AdminModule,
    MarketplaceModule,
  ],
})
export class AppModule {}
