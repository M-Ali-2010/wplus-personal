import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiOpponent, Battle } from '../entities/battle.entity';
import { BattleMode } from '../common/enums';
import { StartBattleDto } from './battles.dto';
import { StreamsGateway } from '../gateway/streams.gateway';

@Injectable()
export class BattlesService {
  constructor(
    @InjectRepository(AiOpponent) private opponentsRepo: Repository<AiOpponent>,
    @InjectRepository(Battle) private battlesRepo: Repository<Battle>,
    private gateway: StreamsGateway,
  ) {}

  async getOpponents() {
    const opponents = await this.opponentsRepo.find({ where: { isActive: true } });
    return opponents.map((o) => ({
      id: o.id,
      slug: o.slug,
      name: o.name,
      tagline: o.tagline,
      difficulty: o.difficulty,
      winRate: o.winRate,
      emoji: o.emoji,
      colorHex: o.colorHex,
    }));
  }

  async startBattle(playerId: string, dto: StartBattleDto) {
    const opponent = await this.opponentsRepo.findOne({ where: { id: dto.opponentId } });
    if (!opponent) throw new NotFoundException('AI opponent not found');

    const totalRounds = dto.mode === BattleMode.CLASSIC ? 3 : 1;

    const battle = this.battlesRepo.create({
      streamId: dto.streamId,
      playerId,
      opponentId: opponent.id,
      mode: dto.mode,
      totalRounds,
      isActive: true,
    });
    await this.battlesRepo.save(battle);

    const payload = {
      battleId: battle.id,
      streamId: dto.streamId,
      mode: dto.mode,
      opponent: {
        id: opponent.id,
        name: opponent.name,
        emoji: opponent.emoji,
      },
      totalRounds,
      currentRound: 1,
    };

    this.gateway.emitBattleEvent(dto.streamId, 'battle.started', payload);

    return payload;
  }

  async updateScore(battleId: string, playerScore: number, aiScore: number) {
    const battle = await this.battlesRepo.findOne({ where: { id: battleId } });
    if (!battle) throw new NotFoundException('Battle not found');

    battle.playerScore = playerScore;
    battle.aiScore = aiScore;
    await this.battlesRepo.save(battle);

    this.gateway.emitBattleEvent(battle.streamId, 'battle.score_update', {
      battleId,
      playerScore,
      aiScore,
    });

    return { battleId, playerScore, aiScore };
  }

  async endBattle(battleId: string, winnerId?: string) {
    const battle = await this.battlesRepo.findOne({ where: { id: battleId } });
    if (!battle) throw new NotFoundException('Battle not found');

    battle.isActive = false;
    battle.endedAt = new Date();
    battle.winnerId = winnerId;
    await this.battlesRepo.save(battle);

    this.gateway.emitBattleEvent(battle.streamId, 'battle.ended', {
      battleId,
      winnerId,
      playerScore: battle.playerScore,
      aiScore: battle.aiScore,
    });

    return battle;
  }

  async getLeaderboard() {
    const users = await this.battlesRepo.manager.query(`
      SELECT u.id, u.username, u."displayName", u.trophies, u."isVerified"
      FROM users u
      WHERE u.trophies > 0
      ORDER BY u.trophies DESC
      LIMIT 20
    `);

    return users.map((u: Record<string, unknown>, index: number) => ({
      rank: index + 1,
      user: {
        id: u.id,
        username: u.username,
        displayName: u.displayName,
        isVerified: u.isVerified,
      },
      trophies: Number(u.trophies),
    }));
  }
}
