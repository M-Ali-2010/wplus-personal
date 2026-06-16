import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto, LoginDto } from './auth.dto';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('api/auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Req() req: { user: Parameters<AuthService['toPublicUser']>[0] & { wallet?: unknown } }) {
    return {
      user: this.authService.toPublicUser(req.user),
      wallet: req.user.wallet
        ? {
            balance: Number((req.user.wallet as { balance: number }).balance),
            pendingBalance: Number((req.user.wallet as { pendingBalance: number }).pendingBalance),
            currency: (req.user.wallet as { currency: string }).currency,
          }
        : null,
    };
  }
}
