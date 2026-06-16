import {
  Column,
  CreateDateColumn,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { GiftAssetType } from '../common/enums';
import { GiftTransaction } from './gift-transaction.entity';

@Entity('gift_categories')
export class GiftCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  slug: string;

  @Column()
  title: string;

  @Column({ default: 0 })
  sortOrder: number;
}

@Entity('gifts')
export class Gift {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column()
  categorySlug: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price: number;

  @Column({ nullable: true })
  assetUrl?: string;

  @Column({ type: 'enum', enum: GiftAssetType, default: GiftAssetType.GIF })
  assetType: GiftAssetType;

  @Column({ nullable: true })
  emoji?: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: 0 })
  sortOrder: number;

  @OneToMany(() => GiftTransaction, (gt) => gt.gift)
  giftTransactions: GiftTransaction[];

  @CreateDateColumn()
  createdAt: Date;
}
