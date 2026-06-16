import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { BattleDifficulty, BattleMode } from '../common/enums';

@Entity('ai_opponents')
export class AiOpponent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  slug: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  tagline?: string;

  @Column({ type: 'enum', enum: BattleDifficulty })
  difficulty: BattleDifficulty;

  @Column({ default: 50 })
  winRate: number;

  @Column({ nullable: true })
  emoji?: string;

  @Column({ nullable: true })
  colorHex?: string;

  @Column({ default: true })
  isActive: boolean;
}

@Entity('battles')
export class Battle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  streamId: string;

  @Column()
  playerId: string;

  @Column()
  opponentId: string;

  @Column({ type: 'enum', enum: BattleMode })
  mode: BattleMode;

  @Column({ default: 1 })
  currentRound: number;

  @Column({ default: 3 })
  totalRounds: number;

  @Column({ default: 0 })
  playerScore: number;

  @Column({ default: 0 })
  aiScore: number;

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  winnerId?: string;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ nullable: true })
  endedAt?: Date;
}
