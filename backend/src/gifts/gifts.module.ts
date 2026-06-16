import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Gift } from '../entities/gift.entity';
import { GiftTransaction } from '../entities/gift-transaction.entity';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { WalletModule } from '../wallet/wallet.module';
import { GatewayModule } from '../gateway/gateway.module';
import { GiftsService } from './gifts.service';
import { GiftsController } from './gifts.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Gift, GiftTransaction, User, Stream]),
    WalletModule,
    forwardRef(() => GatewayModule),
  ],
  controllers: [GiftsController],
  providers: [GiftsService],
  exports: [GiftsService],
})
export class GiftsModule {}
