import { Module, forwardRef } from '@nestjs/common';
import { StreamsGateway } from './streams.gateway';

@Module({
  providers: [StreamsGateway],
  exports: [StreamsGateway],
})
export class GatewayModule {}
