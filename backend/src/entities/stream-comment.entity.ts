import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Stream } from './stream.entity';
import { User } from './user.entity';

@Entity('stream_comments')
export class StreamComment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Stream, (stream) => stream.comments)
  stream: Stream;

  @Column()
  streamId: string;

  @ManyToOne(() => User)
  user: User;

  @Column()
  userId: string;

  @Column({ type: 'text' })
  text: string;

  @Column({ default: false })
  isAi: boolean;

  @Column({ default: false })
  isGift: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
