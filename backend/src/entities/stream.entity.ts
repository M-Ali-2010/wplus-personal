import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { StreamStatus } from '../common/enums';
import { User } from './user.entity';
import { StreamComment } from './stream-comment.entity';

@Entity('streams')
export class Stream {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @ManyToOne(() => User, (user) => user.streams)
  creator: User;

  @Column()
  creatorId: string;

  @Column({ type: 'enum', enum: StreamStatus, default: StreamStatus.SCHEDULED })
  status: StreamStatus;

  @Column({ nullable: true })
  category?: string;

  @Column({ nullable: true })
  thumbnailUrl?: string;

  @Column({ nullable: true })
  livekitRoom?: string;

  @Column({ default: 0 })
  viewerCount: number;

  @Column({ default: 0 })
  peakViewers: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  giftsTotal: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  donationsTotal: number;

  @Column({ default: 0 })
  likesCount: number;

  @Column({ default: true })
  giftsEnabled: boolean;

  @Column({ default: true })
  donationsEnabled: boolean;

  @Column({ default: false })
  aiEnabled: boolean;

  @Column({ nullable: true })
  startedAt?: Date;

  @Column({ nullable: true })
  endedAt?: Date;

  @OneToMany(() => StreamComment, (comment) => comment.stream)
  comments: StreamComment[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
