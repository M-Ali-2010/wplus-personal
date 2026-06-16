import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { GiftsService } from './gifts.service';
import { SendGiftDto } from './gifts.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/gifts')
export class GiftsController {
  constructor(private giftsService: GiftsService) {}

  @Get()
  getCatalog() {
    return this.giftsService.getCatalog();
  }

  @UseGuards(JwtAuthGuard)
  @Post('send')
  sendGift(@Req() req: { user: User }, @Body() dto: SendGiftDto) {
    return this.giftsService.sendGift(req.user.id, dto);
  }
}
