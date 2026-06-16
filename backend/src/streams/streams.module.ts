import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Stream } from '../entities/stream.entity';
import { StreamComment } from '../entities/stream-comment.entity';
import { User } from '../entities/user.entity';
import { AuthModule } from '../auth/auth.module';
import { GatewayModule } from '../gateway/gateway.module';
import { RedisService } from '../common/redis.service';
import { LivekitService } from '../common/livekit.service';
import { StreamsService } from './streams.service';
import { StreamsController } from './streams.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Stream, StreamComment, User]),
    AuthModule,
    forwardRef(() => GatewayModule),
  ],
  controllers: [StreamsController],
  providers: [StreamsService, RedisService, LivekitService],
  exports: [StreamsService],
})
export class StreamsModule {}
