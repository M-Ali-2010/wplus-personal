import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { MarketplaceService } from './marketplace.service';
import { CreateJobDto, ApplyJobDto } from './marketplace.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/marketplace')
export class MarketplaceController {
  constructor(private marketplaceService: MarketplaceService) {}

  @Get('jobs')
  getJobs(@Query('category') category?: string) {
    return this.marketplaceService.getJobs(category);
  }

  @Get('jobs/:id')
  getJob(@Param('id') id: string) {
    return this.marketplaceService.getJob(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('jobs')
  createJob(@Req() req: { user: User }, @Body() dto: CreateJobDto) {
    return this.marketplaceService.createJob(req.user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('jobs/:id/apply')
  applyJob(
    @Param('id') id: string,
    @Req() req: { user: User },
    @Body() dto: ApplyJobDto,
  ) {
    return this.marketplaceService.applyJob(id, req.user.id, dto.coverLetter);
  }
}
