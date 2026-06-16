import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { TopUpDto } from './wallet.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/wallet')
@UseGuards(JwtAuthGuard)
export class WalletController {
  constructor(private walletService: WalletService) {}

  @Get()
  getWallet(@Req() req: { user: User }) {
    return this.walletService.getWallet(req.user.id);
  }

  @Get('transactions')
  getTransactions(@Req() req: { user: User }) {
    return this.walletService.getTransactions(req.user.id);
  }

  @Post('topup')
  topUp(@Req() req: { user: User }, @Body() dto: TopUpDto) {
    return this.walletService.topUp(req.user.id, dto);
  }
}
