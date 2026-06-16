import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Donation } from '../entities/donation.entity';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { WalletModule } from '../wallet/wallet.module';
import { GatewayModule } from '../gateway/gateway.module';
import { DonationsService } from './donations.service';
import { DonationsController } from './donations.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Donation, User, Stream]),
    WalletModule,
    forwardRef(() => GatewayModule),
  ],
  controllers: [DonationsController],
  providers: [DonationsService],
})
export class DonationsModule {}
