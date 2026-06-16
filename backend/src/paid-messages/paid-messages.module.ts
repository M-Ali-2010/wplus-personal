import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaidMessage } from '../entities/paid-message.entity';
import { User } from '../entities/user.entity';
import { Stream } from '../entities/stream.entity';
import { StreamComment } from '../entities/stream-comment.entity';
import { WalletModule } from '../wallet/wallet.module';
import { GatewayModule } from '../gateway/gateway.module';
import { AuthModule } from '../auth/auth.module';
import { PaidMessagesService } from './paid-messages.service';
import { PaidMessagesController } from './paid-messages.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([PaidMessage, User, Stream, StreamComment]),
    WalletModule,
    GatewayModule,
    AuthModule,
  ],
  controllers: [PaidMessagesController],
  providers: [PaidMessagesService],
  exports: [PaidMessagesService],
})
export class PaidMessagesModule {}
