import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { SubscriptionsService } from './subscriptions.service';
import { CreatePremiumPostDto, PurchasePremiumPostDto, SubscribeDto } from './subscriptions.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionsController {
  constructor(private subscriptionsService: SubscriptionsService) {}

  @Post('subscribe')
  subscribe(@Req() req: { user: User }, @Body() dto: SubscribeDto) {
    return this.subscriptionsService.subscribe(req.user.id, dto);
  }

  @Get('mine')
  mySubscriptions(@Req() req: { user: User }) {
    return this.subscriptionsService.getMySubscriptions(req.user.id);
  }

  @Get('check/:creatorId')
  check(@Req() req: { user: User }, @Param('creatorId') creatorId: string) {
    return this.subscriptionsService.isSubscribed(req.user.id, creatorId);
  }

  @Post('premium-posts')
  createPost(@Req() req: { user: User }, @Body() dto: CreatePremiumPostDto) {
    return this.subscriptionsService.createPremiumPost(req.user.id, dto);
  }

  @Get('premium-posts')
  listPosts(@Query('creatorId') creatorId?: string) {
    return this.subscriptionsService.getPremiumPosts(creatorId);
  }

  @Get('premium-posts/:id')
  getPost(@Req() req: { user: User }, @Param('id') id: string) {
    return this.subscriptionsService.getPremiumPost(id, req.user.id);
  }

  @Post('premium-posts/:id/purchase')
  purchase(
    @Req() req: { user: User },
    @Param('id') id: string,
    @Body() dto: PurchasePremiumPostDto,
  ) {
    return this.subscriptionsService.purchasePost(req.user.id, id, dto.idempotencyKey);
  }
}
