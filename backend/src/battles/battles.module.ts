import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiOpponent, Battle } from '../entities/battle.entity';
import { GatewayModule } from '../gateway/gateway.module';
import { BattlesService } from './battles.service';
import { BattlesController } from './battles.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([AiOpponent, Battle]),
    forwardRef(() => GatewayModule),
  ],
  controllers: [BattlesController],
  providers: [BattlesService],
})
export class BattlesModule {}
