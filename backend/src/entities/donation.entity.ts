import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity('donations')
export class Donation {
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
  postId?: string;

  @Column({ nullable: true })
  streamId?: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column({ nullable: true, type: 'text' })
  message?: string;

  @Column()
  transactionId: string;

  @CreateDateColumn()
  createdAt: Date;
}
