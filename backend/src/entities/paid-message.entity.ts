import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('paid_messages')
export class PaidMessage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  senderId: string;

  @ManyToOne(() => User, { nullable: true, eager: false })
  @JoinColumn({ name: 'senderId' })
  sender?: User;

  @Column({ nullable: true })
  receiverId: string;

  @ManyToOne(() => User, { nullable: true, eager: false })
  @JoinColumn({ name: 'receiverId' })
  receiver?: User;

  @Column({ nullable: true })
  streamId?: string;

  @Column({ nullable: true })
  postId?: string;

  @Column({ type: 'text' })
  text: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column()
  transactionId: string;

  @CreateDateColumn()
  createdAt: Date;
}
