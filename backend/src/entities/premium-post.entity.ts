import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('premium_posts')
export class PremiumPost {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  creatorId: string;

  @Column()
  title: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  price: number;

  @Column({ default: true })
  isPremium: boolean;

  @Column({ nullable: true })
  thumbnailUrl?: string;

  @CreateDateColumn()
  createdAt: Date;
}
