import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { DonationsService } from './donations.service';
import { CreateDonationDto } from './donations.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/donations')
@UseGuards(JwtAuthGuard)
export class DonationsController {
  constructor(private donationsService: DonationsService) {}

  @Post()
  create(@Req() req: { user: User }, @Body() dto: CreateDonationDto) {
    return this.donationsService.create(req.user.id, dto);
  }
}
