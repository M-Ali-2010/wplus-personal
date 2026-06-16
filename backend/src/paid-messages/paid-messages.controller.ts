import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { PaidMessagesService } from './paid-messages.service';
import { SendPaidMessageDto } from './paid-messages.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/paid-messages')
@UseGuards(JwtAuthGuard)
export class PaidMessagesController {
  constructor(private paidMessagesService: PaidMessagesService) {}

  @Post()
  send(@Req() req: { user: User }, @Body() dto: SendPaidMessageDto) {
    return this.paidMessagesService.send(req.user.id, dto);
  }

  @Get('received')
  received(@Req() req: { user: User }) {
    return this.paidMessagesService.getForCreator(req.user.id);
  }
}
