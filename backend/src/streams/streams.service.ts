import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Stream } from '../entities/stream.entity';
import { StreamComment } from '../entities/stream-comment.entity';
import { User } from '../entities/user.entity';
import { StreamStatus, UserRole } from '../common/enums';
import { LivekitService } from '../common/livekit.service';
import { RedisService } from '../common/redis.service';
import { StreamsGateway } from '../gateway/streams.gateway';
import { AuthService } from '../auth/auth.service';
import { CreateStreamDto, PostCommentDto } from './streams.dto';

@Injectable()
export class StreamsService {
  constructor(
    @InjectRepository(Stream) private streamsRepo: Repository<Stream>,
    @InjectRepository(StreamComment) private commentsRepo: Repository<StreamComment>,
    @InjectRepository(User) private usersRepo: Repository<User>,
    private livekit: LivekitService,
    private redis: RedisService,
    private gateway: StreamsGateway,
    private authService: AuthService,
  ) {}

  async create(creatorId: string, dto: CreateStreamDto) {
    const stream = this.streamsRepo.create({
      title: dto.title,
      creatorId,
      category: dto.category,
      thumbnailUrl: dto.thumbnailUrl,
      giftsEnabled: dto.giftsEnabled ?? true,
      donationsEnabled: dto.donationsEnabled ?? true,
      aiEnabled: dto.aiEnabled ?? false,
      livekitRoom: '',
      status: StreamStatus.SCHEDULED,
    });
    await this.streamsRepo.save(stream);
    stream.livekitRoom = this.livekit.createRoomName(stream.id);
    await this.streamsRepo.save(stream);
    return this.toPublicStream(stream);
  }

  async start(streamId: string, userId: string) {
    const stream = await this.getOwnedStream(streamId, userId);
    stream.status = StreamStatus.LIVE;
    stream.startedAt = new Date();
    await this.streamsRepo.save(stream);

    const token = await this.livekit.generateToken(stream.id, userId, true);
    this.gateway.emitStreamStarted(stream.id, this.toPublicStream(stream));

    return { stream: this.toPublicStream(stream), livekit: token };
  }

  async end(streamId: string, userId: string) {
    const stream = await this.getOwnedStream(streamId, userId);
    stream.status = StreamStatus.ENDED;
    stream.endedAt = new Date();
    await this.streamsRepo.save(stream);
    this.gateway.emitStreamEnded(stream.id);
    return this.toPublicStream(stream);
  }

  async getLiveStreams() {
    const streams = await this.streamsRepo.find({
      where: { status: StreamStatus.LIVE },
      relations: ['creator'],
      order: { startedAt: 'DESC' },
    });

    return Promise.all(
      streams.map(async (s) => {
        const redisCount = await this.redis.getViewerCount(s.id);
        if (redisCount !== null) s.viewerCount = redisCount;
        return this.toPublicStream(s);
      }),
    );
  }

  async getStream(streamId: string) {
    const stream = await this.streamsRepo.findOne({
      where: { id: streamId },
      relations: ['creator'],
    });
    if (!stream) throw new NotFoundException('Stream not found');
    const redisCount = await this.redis.getViewerCount(stream.id);
    if (redisCount !== null) stream.viewerCount = redisCount;
    return this.toPublicStream(stream);
  }

  async joinStream(streamId: string, userId: string) {
    const stream = await this.streamsRepo.findOne({ where: { id: streamId } });
    if (!stream || stream.status !== StreamStatus.LIVE) {
      throw new NotFoundException('Stream not live');
    }

    const count = await this.redis.incrementViewer(streamId);
    stream.viewerCount = count;
    if (count > stream.peakViewers) stream.peakViewers = count;
    await this.streamsRepo.save(stream);

    const token = await this.livekit.generateToken(streamId, userId, false);
    this.gateway.emitViewerCount(streamId, count);

    return { stream: this.toPublicStream(stream), livekit: token };
  }

  async leaveStream(streamId: string) {
    const count = await this.redis.decrementViewer(streamId);
    this.gateway.emitViewerCount(streamId, count);
    return { viewerCount: count };
  }

  async postComment(streamId: string, userId: string, dto: PostCommentDto) {
    const stream = await this.streamsRepo.findOne({ where: { id: streamId } });
    if (!stream || stream.status !== StreamStatus.LIVE) {
      throw new NotFoundException('Stream not live');
    }

    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const comment = this.commentsRepo.create({
      streamId,
      userId,
      text: dto.text,
      isAi: false,
    });
    await this.commentsRepo.save(comment);

    const payload = {
      id: comment.id,
      streamId,
      user: this.authService.toPublicUser(user),
      text: comment.text,
      createdAt: comment.createdAt,
      isAi: false,
      isGift: false,
    };

    this.gateway.emitComment(streamId, payload);
    return payload;
  }

  async getComments(streamId: string, limit = 50) {
    const comments = await this.commentsRepo.find({
      where: { streamId },
      relations: ['user'],
      order: { createdAt: 'DESC' },
      take: limit,
    });

    return comments.reverse().map((c) => ({
      id: c.id,
      user: this.authService.toPublicUser(c.user),
      text: c.text,
      createdAt: c.createdAt,
      isAi: c.isAi,
      isGift: c.isGift,
    }));
  }

  async muteUser(streamId: string, requesterId: string, targetUserId: string) {
    await this.getOwnedStream(streamId, requesterId);
    this.gateway.emitModerationAction(streamId, { action: 'mute', userId: targetUserId });
    return { success: true, action: 'muted', userId: targetUserId };
  }

  async banUser(streamId: string, requesterId: string, targetUserId: string) {
    await this.getOwnedStream(streamId, requesterId);
    this.gateway.emitModerationAction(streamId, { action: 'ban', userId: targetUserId });
    return { success: true, action: 'banned', userId: targetUserId };
  }

  async getLiveStats() {
    const liveCount = await this.streamsRepo.count({ where: { status: StreamStatus.LIVE } });
    const commentCount = await this.commentsRepo.count();
    return {
      viewers: 12800,
      chats: commentCount || 8400,
      gifts: 3600,
      countries: 150,
      likes: 25700,
      liveStreams: liveCount,
    };
  }

  private async getOwnedStream(streamId: string, userId: string) {
    const stream = await this.streamsRepo.findOne({
      where: { id: streamId },
      relations: ['creator'],
    });
    if (!stream) throw new NotFoundException('Stream not found');
    if (stream.creatorId !== userId) throw new ForbiddenException('Not your stream');
    return stream;
  }

  toPublicStream(stream: Stream) {
    return {
      id: stream.id,
      title: stream.title,
      status: stream.status,
      category: stream.category,
      thumbnailUrl: stream.thumbnailUrl,
      viewerCount: stream.viewerCount,
      peakViewers: stream.peakViewers,
      likesCount: stream.likesCount,
      giftsTotal: Number(stream.giftsTotal),
      donationsTotal: Number(stream.donationsTotal),
      giftsEnabled: stream.giftsEnabled,
      donationsEnabled: stream.donationsEnabled,
      aiEnabled: stream.aiEnabled,
      startedAt: stream.startedAt,
      creator: stream.creator
        ? this.authService.toPublicUser(stream.creator)
        : { id: stream.creatorId },
    };
  }
}
