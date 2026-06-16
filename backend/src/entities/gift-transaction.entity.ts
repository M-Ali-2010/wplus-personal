import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Gift } from './gift.entity';

@Entity('gift_transactions')
export class GiftTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Gift)
  gift: Gift;

  @Column()
  giftId: string;

  @Column()
  senderId: string;

  @Column()
  receiverId: string;

  @Column({ nullable: true })
  streamId?: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column()
  transactionId: string;

  @CreateDateColumn()
  createdAt: Date;
}
