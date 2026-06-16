import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { StreamsService } from './streams.service';
import { CreateStreamDto, PostCommentDto } from './streams.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/streams')
export class StreamsController {
  constructor(private streamsService: StreamsService) {}

  @Get('live')
  getLive() {
    return this.streamsService.getLiveStreams();
  }

  @Get('stats')
  getStats() {
    return this.streamsService.getLiveStats();
  }

  @Get(':id')
  getStream(@Param('id') id: string) {
    return this.streamsService.getStream(id);
  }

  @Get(':id/comments')
  getComments(@Param('id') id: string) {
    return this.streamsService.getComments(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Req() req: { user: User }, @Body() dto: CreateStreamDto) {
    return this.streamsService.create(req.user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/start')
  start(@Param('id') id: string, @Req() req: { user: User }) {
    return this.streamsService.start(id, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/end')
  end(@Param('id') id: string, @Req() req: { user: User }) {
    return this.streamsService.end(id, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/join')
  join(@Param('id') id: string, @Req() req: { user: User }) {
    return this.streamsService.joinStream(id, req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/leave')
  leave(@Param('id') id: string) {
    return this.streamsService.leaveStream(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/comments')
  postComment(
    @Param('id') id: string,
    @Req() req: { user: User },
    @Body() dto: PostCommentDto,
  ) {
    return this.streamsService.postComment(id, req.user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/mute')
  muteUser(
    @Param('id') id: string,
    @Req() req: { user: User },
    @Body() body: { userId: string },
  ) {
    return this.streamsService.muteUser(id, req.user.id, body.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/ban')
  banUser(
    @Param('id') id: string,
    @Req() req: { user: User },
    @Body() body: { userId: string },
  ) {
    return this.streamsService.banUser(id, req.user.id, body.userId);
  }
}
