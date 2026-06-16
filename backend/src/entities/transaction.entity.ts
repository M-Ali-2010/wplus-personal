import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { TransactionStatus, TransactionType } from '../common/enums';
import { User } from './user.entity';

@Entity('transactions')
export class Transaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, (user) => user.transactions)
  user: User;

  @Column()
  userId: string;

  @Column({ nullable: true })
  counterpartyId?: string;

  @Column({ type: 'enum', enum: TransactionType })
  type: TransactionType;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column({ default: 'W' })
  currency: string;

  @Column({ type: 'enum', enum: TransactionStatus, default: TransactionStatus.PENDING })
  status: TransactionStatus;

  @Column({ nullable: true })
  referenceId?: string;

  @Index({ unique: true })
  @Column()
  idempotencyKey: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ nullable: true })
  counterpartyName?: string;

  @CreateDateColumn()
  createdAt: Date;
}
