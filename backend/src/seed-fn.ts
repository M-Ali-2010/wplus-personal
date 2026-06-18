import * as bcrypt from 'bcryptjs';
import { DataSource } from 'typeorm';
import { User } from './entities/user.entity';
import { Wallet } from './entities/wallet.entity';
import { Gift, GiftCategory } from './entities/gift.entity';
import { AiOpponent } from './entities/battle.entity';
import { Stream } from './entities/stream.entity';
import { PremiumPost } from './entities/premium-post.entity';
import { UserRole, StreamStatus, GiftAssetType, BattleDifficulty } from './common/enums';

export async function seed(dataSource: DataSource) {
  const usersRepo = dataSource.getRepository(User);
  const walletsRepo = dataSource.getRepository(Wallet);
  const giftsRepo = dataSource.getRepository(Gift);
  const categoriesRepo = dataSource.getRepository(GiftCategory);
  const opponentsRepo = dataSource.getRepository(AiOpponent);
  const streamsRepo = dataSource.getRepository(Stream);
  const premiumRepo = dataSource.getRepository(PremiumPost);

  const categories = [
    { slug: 'popular', title: 'Popular', sortOrder: 1 },
    { slug: 'luxury', title: 'Luxury', sortOrder: 2 },
    { slug: 'exclusive', title: 'Exclusive', sortOrder: 3 },
  ];
  for (const cat of categories) {
    const exists = await categoriesRepo.findOne({ where: { slug: cat.slug } });
    if (!exists) await categoriesRepo.save(categoriesRepo.create(cat));
  }

  const accounts = [
    { email: 'creator@wplus.dev', username: 'rita', displayName: 'Rita', password: 'password123', role: UserRole.CREATOR, balance: 2500, isVerified: true, followersCount: 23400, trophies: 12850, bio: 'Live every day • Music & vibes' },
    { email: 'user@wplus.dev', username: 'you', displayName: 'You', password: 'password123', role: UserRole.CREATOR, balance: 2500, isVerified: true, followersCount: 1240, trophies: 4250, bio: 'W+ creator' },
    { email: 'viewer@wplus.dev', username: 'alex', displayName: 'Alex', password: 'password123', role: UserRole.USER, balance: 500, isVerified: false, followersCount: 0, trophies: 0 },
    { email: 'admin@wplus.dev', username: 'admin', displayName: 'Admin', password: 'admin123', role: UserRole.ADMIN, balance: 0, isVerified: true, followersCount: 0, trophies: 0 },
  ];

  const createdUsers: User[] = [];
  for (const acc of accounts) {
    let user = await usersRepo.findOne({ where: { email: acc.email } });
    if (!user) {
      user = usersRepo.create({
        email: acc.email, username: acc.username, displayName: acc.displayName,
        passwordHash: await bcrypt.hash(acc.password, 10),
        role: acc.role, isVerified: acc.isVerified,
        followersCount: acc.followersCount, trophies: acc.trophies, bio: acc.bio,
      });
      await usersRepo.save(user);
      const wallet = walletsRepo.create({ userId: user.id, balance: acc.balance, currency: 'W' });
      await walletsRepo.save(wallet);
    }
    createdUsers.push(user!);
  }

  const rita = createdUsers.find((u) => u.username === 'rita')!;
  const niko = createdUsers.find((u) => u.username === 'you');

  const giftData = [
    { title: 'Heart', price: 10, categorySlug: 'popular', assetType: GiftAssetType.GIF, emoji: '❤️', sortOrder: 1 },
    { title: 'Rose', price: 20, categorySlug: 'popular', assetType: GiftAssetType.GIF, emoji: '🌹', sortOrder: 2 },
    { title: 'Rocket', price: 50, categorySlug: 'popular', assetType: GiftAssetType.LOTTIE, emoji: '🚀', sortOrder: 3 },
    { title: 'Crown', price: 100, categorySlug: 'popular', assetType: GiftAssetType.LOTTIE, emoji: '👑', sortOrder: 4 },
    { title: 'Galaxy', price: 100, categorySlug: 'popular', assetType: GiftAssetType.MP4, emoji: '🌌', sortOrder: 5 },
    { title: 'Love Bomb', price: 300, categorySlug: 'popular', assetType: GiftAssetType.MP4, emoji: '💣', sortOrder: 6 },
    { title: 'Flying Dragon', price: 500, categorySlug: 'popular', assetType: GiftAssetType.MP4, emoji: '🐉', sortOrder: 7 },
    { title: 'Disco Ball', price: 150, categorySlug: 'luxury', assetType: GiftAssetType.LOTTIE, emoji: '🪩', sortOrder: 8 },
    { title: 'Crystal Castle', price: 1000, categorySlug: 'luxury', assetType: GiftAssetType.MP4, emoji: '🏰', sortOrder: 9 },
    { title: 'Golden Lion', price: 1000, categorySlug: 'luxury', assetType: GiftAssetType.MP4, emoji: '🦁', sortOrder: 10 },
    { title: 'Private Jet', price: 2000, categorySlug: 'luxury', assetType: GiftAssetType.MP4, emoji: '✈️', sortOrder: 11 },
    { title: 'Yacht', price: 5000, categorySlug: 'luxury', assetType: GiftAssetType.MP4, emoji: '🛥️', sortOrder: 12 },
    { title: 'Neon Heart', price: 100, categorySlug: 'exclusive', assetType: GiftAssetType.GIF, emoji: '💜', sortOrder: 13 },
    { title: 'Fireworks', price: 200, categorySlug: 'exclusive', assetType: GiftAssetType.LOTTIE, emoji: '🎆', sortOrder: 14 },
    { title: 'Meteor Shower', price: 300, categorySlug: 'exclusive', assetType: GiftAssetType.MP4, emoji: '☄️', sortOrder: 15 },
    { title: 'Space Rocket', price: 500, categorySlug: 'exclusive', assetType: GiftAssetType.MP4, emoji: '🚀', sortOrder: 16 },
  ];
  const existingGifts = await giftsRepo.count();
  if (existingGifts === 0) {
    for (const g of giftData) {
      await giftsRepo.save(giftsRepo.create({ ...g, isActive: true }));
    }
  }

  const opponents = [
    { slug: 'ai_neon', name: 'AI Neon', tagline: 'Energetic and competitive', difficulty: BattleDifficulty.HARD, winRate: 65, emoji: '🤖', colorHex: '0xFF00FFFF' },
    { slug: 'ai_luna', name: 'AI Luna', tagline: 'Charming and witty', difficulty: BattleDifficulty.MEDIUM, winRate: 55, emoji: '🌙', colorHex: '0xFF8A2BE2' },
    { slug: 'ai_titan', name: 'AI Titan', tagline: 'Ultimate challenge', difficulty: BattleDifficulty.EXTREME, winRate: 40, emoji: '⚡', colorHex: '0xFFFF6600' },
  ];
  for (const o of opponents) {
    const exists = await opponentsRepo.findOne({ where: { slug: o.slug } });
    if (!exists) await opponentsRepo.save(opponentsRepo.create({ ...o, isActive: true }));
  }

  const liveCount = await streamsRepo.count({ where: { status: StreamStatus.LIVE } });
  if (liveCount === 0 && rita) {
    await streamsRepo.save([
      streamsRepo.create({ title: 'Evening Vibes 🎵', creatorId: rita.id, status: StreamStatus.LIVE, category: 'Music', viewerCount: 2400, likesCount: 23400, giftsTotal: 12500, donationsTotal: 3200, startedAt: new Date(), livekitRoom: 'demo_room_1' }),
      streamsRepo.create({ title: 'AI Battle Night ⚔️', creatorId: niko?.id ?? rita.id, status: StreamStatus.LIVE, category: 'Gaming', viewerCount: 1800, likesCount: 8900, giftsTotal: 8900, startedAt: new Date(), livekitRoom: 'demo_room_2' }),
    ]);
  }

  const premiumCount = await premiumRepo.count();
  if (premiumCount === 0 && rita) {
    await premiumRepo.save([
      premiumRepo.create({ creatorId: rita.id, title: 'Behind the Scenes', content: 'Exclusive studio session footage.', price: 50, isPremium: true }),
      premiumRepo.create({ creatorId: rita.id, title: 'Free Preview', content: 'Welcome to my premium channel!', price: 0, isPremium: false }),
    ]);
  }
}
