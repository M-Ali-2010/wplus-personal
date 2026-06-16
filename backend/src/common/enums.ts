export enum UserRole {
  GUEST = 'guest',
  USER = 'user',
  CREATOR = 'creator',
  MODERATOR = 'moderator',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
}

export enum StreamStatus {
  SCHEDULED = 'scheduled',
  LIVE = 'live',
  ENDED = 'ended',
}

export enum GiftAssetType {
  GIF = 'gif',
  LOTTIE = 'lottie',
  MP4 = 'mp4',
}

export enum TransactionType {
  TOPUP = 'topup',
  GIFT = 'gift',
  DONATION = 'donation',
  PAID_MESSAGE = 'paid_message',
  SUBSCRIPTION = 'subscription',
  PURCHASE = 'purchase',
  PAYOUT = 'payout',
  REFUND = 'refund',
  COMMISSION = 'commission',
}

export enum TransactionStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export enum BattleMode {
  CLASSIC = 'classic',
  SPEED = 'speed',
  SURVIVAL = 'survival',
}

export enum BattleDifficulty {
  MEDIUM = 'medium',
  HARD = 'hard',
  EXTREME = 'extreme',
}
