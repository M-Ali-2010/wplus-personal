import '../models/battle.dart';
import '../models/gift.dart';
import '../models/post.dart';
import '../models/stream.dart';
import '../models/user.dart';
import '../models/wallet.dart';

abstract final class MockData {
  static const currentUser = UserProfile(
    id: 'u1',
    username: 'you',
    displayName: 'You',
    role: UserRole.creator,
    isVerified: true,
    followersCount: 1240,
    followingCount: 89,
  );

  static final creators = [
    const UserProfile(
      id: 'c1',
      username: 'rita',
      displayName: 'Rita',
      role: UserRole.creator,
      isVerified: true,
      followersCount: 23400,
      followingCount: 120,
      bio: 'Live every day • Music & vibes',
    ),
    const UserProfile(
      id: 'c2',
      username: 'niko',
      displayName: 'Niko',
      role: UserRole.creator,
      isVerified: true,
      followersCount: 15600,
      followingCount: 340,
      bio: 'Gaming & AI battles',
    ),
    const UserProfile(
      id: 'c3',
      username: 'luna',
      displayName: 'Luna',
      role: UserRole.creator,
      isVerified: false,
      followersCount: 8900,
      followingCount: 210,
      bio: 'Art & creative streams',
    ),
  ];

  static final liveStreams = [
    LiveStream(
      id: 's1',
      title: 'Evening Vibes 🎵',
      creator: creators[0],
      viewerCount: 2400,
      status: StreamStatus.live,
      category: 'Music',
      likesCount: 23400,
      giftsTotal: 12500,
      donationsTotal: 3200,
    ),
    LiveStream(
      id: 's2',
      title: 'AI Battle Night ⚔️',
      creator: creators[1],
      viewerCount: 1800,
      status: StreamStatus.live,
      category: 'Gaming',
      likesCount: 8900,
      giftsTotal: 8900,
    ),
    LiveStream(
      id: 's3',
      title: 'Digital Art Session',
      creator: creators[2],
      viewerCount: 456,
      status: StreamStatus.live,
      category: 'Art',
      likesCount: 2100,
    ),
  ];

  static final gifts = [
    const Gift(id: 'g1', title: 'Heart', price: 10, category: GiftCategory.popular, assetType: GiftAssetType.gif, emoji: '❤️'),
    const Gift(id: 'g2', title: 'Rose', price: 20, category: GiftCategory.popular, assetType: GiftAssetType.gif, emoji: '🌹'),
    const Gift(id: 'g3', title: 'Rocket', price: 50, category: GiftCategory.popular, assetType: GiftAssetType.lottie, emoji: '🚀'),
    const Gift(id: 'g4', title: 'Crown', price: 100, category: GiftCategory.popular, assetType: GiftAssetType.lottie, emoji: '👑'),
    const Gift(id: 'g5', title: 'Galaxy', price: 100, category: GiftCategory.popular, assetType: GiftAssetType.mp4, emoji: '🌌'),
    const Gift(id: 'g6', title: 'Love Bomb', price: 300, category: GiftCategory.popular, assetType: GiftAssetType.mp4, emoji: '💣'),
    const Gift(id: 'g7', title: 'Flying Dragon', price: 500, category: GiftCategory.popular, assetType: GiftAssetType.mp4, emoji: '🐉'),
    const Gift(id: 'g8', title: 'Disco Ball', price: 150, category: GiftCategory.luxury, assetType: GiftAssetType.lottie, emoji: '🪩'),
    const Gift(id: 'g9', title: 'Crystal Castle', price: 1000, category: GiftCategory.luxury, assetType: GiftAssetType.mp4, emoji: '🏰'),
    const Gift(id: 'g10', title: 'Golden Lion', price: 1000, category: GiftCategory.luxury, assetType: GiftAssetType.mp4, emoji: '🦁'),
    const Gift(id: 'g11', title: 'Private Jet', price: 2000, category: GiftCategory.luxury, assetType: GiftAssetType.mp4, emoji: '✈️'),
    const Gift(id: 'g12', title: 'Yacht', price: 5000, category: GiftCategory.luxury, assetType: GiftAssetType.mp4, emoji: '🛥️'),
    const Gift(id: 'g13', title: 'Neon Heart', price: 100, category: GiftCategory.exclusive, assetType: GiftAssetType.gif, emoji: '💜'),
    const Gift(id: 'g14', title: 'Fireworks', price: 200, category: GiftCategory.exclusive, assetType: GiftAssetType.lottie, emoji: '🎆'),
    const Gift(id: 'g15', title: 'Meteor Shower', price: 300, category: GiftCategory.exclusive, assetType: GiftAssetType.mp4, emoji: '☄️'),
    const Gift(id: 'g16', title: 'Space Rocket', price: 500, category: GiftCategory.exclusive, assetType: GiftAssetType.mp4, emoji: '🚀'),
  ];

  static final posts = [
    Post(
      id: 'p1',
      creator: creators[0],
      content: 'New track dropping tonight on live! Who\'s ready? 🔥',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 1240,
      donationsCount: 89,
      donationsTotal: 450,
    ),
    Post(
      id: 'p2',
      creator: creators[1],
      content: 'Just finished an epic AI battle. Replay coming soon!',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likesCount: 890,
      donationsCount: 45,
      donationsTotal: 220,
    ),
    Post(
      id: 'p3',
      creator: creators[2],
      content: 'Exclusive art process — premium subscribers only ✨',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      likesCount: 456,
      isPremium: true,
    ),
  ];

  static const wallet = Wallet(balance: 2500, currency: 'W', pendingBalance: 150);

  static final streamComments = [
    StreamComment(
      id: 'cm1',
      user: const UserProfile(id: 'v1', username: 'alex', displayName: 'Alex'),
      text: 'This is fire! 🔥',
      createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
    StreamComment(
      id: 'cm2',
      user: creators[1],
      text: 'Sent Flying Dragon x3',
      createdAt: DateTime.now().subtract(const Duration(seconds: 15)),
    ),
    StreamComment(
      id: 'cm3',
      user: const UserProfile(id: 'v2', username: 'maria', displayName: 'Maria'),
      text: 'Love this stream!',
      createdAt: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
  ];

  static final recentTransactions = [
    Transaction(
      id: 't1',
      type: TransactionType.gift,
      amount: -500,
      status: TransactionStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      counterpartyName: 'Rita',
      description: 'Flying Dragon',
    ),
    Transaction(
      id: 't2',
      type: TransactionType.donation,
      amount: -25,
      status: TransactionStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      counterpartyName: 'Niko',
      description: 'Support donation',
    ),
    Transaction(
      id: 't3',
      type: TransactionType.topup,
      amount: 1000,
      status: TransactionStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Wallet top-up',
    ),
  ];

  static const liveStats = {
    'viewers': 12800,
    'chats': 8400,
    'gifts': 3600,
    'countries': 150,
    'likes': 25700,
  };

  static const aiOpponents = [
    AiOpponent(
      id: 'ai_neon',
      name: 'AI Neon',
      tagline: 'Energetic and competitive AI opponent',
      difficulty: BattleDifficulty.hard,
      winRate: 65,
      emoji: '🤖',
      colorHex: 0xFF00FFFF,
    ),
    AiOpponent(
      id: 'ai_luna',
      name: 'AI Luna',
      tagline: 'Charming and witty AI personality',
      difficulty: BattleDifficulty.medium,
      winRate: 55,
      emoji: '🌙',
      colorHex: 0xFF8A2BE2,
    ),
    AiOpponent(
      id: 'ai_titan',
      name: 'AI Titan',
      tagline: 'The ultimate AI challenge',
      difficulty: BattleDifficulty.extreme,
      winRate: 40,
      emoji: '⚡',
      colorHex: 0xFFFF6600,
    ),
  ];

  static final leaderboard = [
    LeaderboardEntry(rank: 1, user: creators[1], trophies: 15420, isCurrentUser: false),
    LeaderboardEntry(rank: 2, user: creators[0], trophies: 12850, isCurrentUser: false),
    const LeaderboardEntry(
      rank: 3,
      user: UserProfile(id: 'v3', username: 'alexrivers_', displayName: 'alexrivers_'),
      trophies: 11200,
      isCurrentUser: false,
    ),
    LeaderboardEntry(rank: 12, user: currentUser, trophies: 4250, isCurrentUser: true),
  ];

  static const battleRewards = [
    BattleReward(title: 'Win', trophies: 50, xp: 100, icon: '🏆'),
    BattleReward(title: 'MVP', trophies: 100, xp: 200, icon: '⭐'),
    BattleReward(title: 'Win Streak', trophies: 150, xp: 300, icon: '🔥'),
    BattleReward(title: 'Exclusive Chest', trophies: 0, xp: 0, icon: '🎁'),
  ];

  static const giftPackages = [
    (amount: 100.0, bonus: 0.0, priceUsd: 0.99),
    (amount: 500.0, bonus: 50.0, priceUsd: 4.99),
    (amount: 1000.0, bonus: 150.0, priceUsd: 9.99),
    (amount: 5000.0, bonus: 1000.0, priceUsd: 39.99),
  ];
}
