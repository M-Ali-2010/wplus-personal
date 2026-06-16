import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StreamComment } from '../entities/stream-comment.entity';
import { User } from '../entities/user.entity';
import { GenerateCommentDto } from './ai.dto';

const BOT_USERS = [
  { username: 'luna_ai', displayName: 'Luna' },
  { username: 'max_bot', displayName: 'Max' },
  { username: 'mia_neural', displayName: 'Mia' },
  { username: 'alex_ai', displayName: 'Alex' },
  { username: 'zoey_bot', displayName: 'Zoey' },
  { username: 'kai_neural', displayName: 'Kai' },
];

const COMMENTS = [
  'This is fire! 🔥',
  'Love this vibe! 💜',
  "You're amazing! ✨",
  'Keep going! 🚀',
  'Best stream ever! 👑',
  'Sent you a gift! 🎁',
  'AI battle when? ⚔️',
  'This energy is unmatched! 💥',
];

const GIFT_COMMENTS = [
  'Sent Rocket x3 🚀',
  'Sent Diamond x10 💎',
  'Sent Neon Heart 💜',
  'Sent Golden Lion 🦁',
];

@Injectable()
export class AiService {
  constructor(
    private config: ConfigService,
    @InjectRepository(StreamComment) private commentsRepo: Repository<StreamComment>,
    @InjectRepository(User) private usersRepo: Repository<User>,
  ) {}

  async generateComment(dto: GenerateCommentDto) {
    const bot = BOT_USERS[Math.floor(Math.random() * BOT_USERS.length)];
    const includeGift = dto.includeGift ?? Math.random() > 0.7;
    const text = includeGift
      ? GIFT_COMMENTS[Math.floor(Math.random() * GIFT_COMMENTS.length)]
      : COMMENTS[Math.floor(Math.random() * COMMENTS.length)];

    // When OPENAI_API_KEY is set, call OpenAI here
    if (this.config.get('OPENAI_API_KEY')) {
      // TODO: OpenAI integration
    }

    let user = await this.usersRepo.findOne({ where: { username: bot.username } });
    if (!user) {
      user = this.usersRepo.create({
        email: `${bot.username}@wplus.ai`,
        username: bot.username,
        displayName: bot.displayName,
        passwordHash: 'ai_bot',
      });
      await this.usersRepo.save(user);
    }

    const comment = this.commentsRepo.create({
      streamId: dto.streamId,
      userId: user.id,
      text,
      isAi: true,
      isGift: includeGift,
    });
    await this.commentsRepo.save(comment);

    return {
      id: comment.id,
      streamId: dto.streamId,
      user: {
        id: user.id,
        username: user.username,
        displayName: user.displayName,
      },
      text,
      createdAt: comment.createdAt,
      isAi: true,
      isGift: includeGift,
    };
  }
}
