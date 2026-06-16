import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('subscriptions')
export class Subscription {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  subscriberId: string;

  @Column()
  creatorId: string;

  @Column({ default: 'premium' })
  tier: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price: number;

  @Column({ type: 'timestamptz' })
  expiresAt: Date;

  @Column({ default: true })
  isActive: boolean;

  @Column()
  transactionId: string;

  @CreateDateColumn()
  createdAt: Date;
}
