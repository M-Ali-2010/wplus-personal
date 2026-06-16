import 'user.dart';

enum GiftAssetType { gif, lottie, mp4 }

enum GiftCategory { popular, luxury, exclusive }

class Gift {
  const Gift({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.assetType,
    this.assetUrl,
    this.emoji = '🎁',
    this.isActive = true,
  });

  final String id;
  final String title;
  final double price;
  final GiftCategory category;
  final GiftAssetType assetType;
  final String? assetUrl;
  final String emoji;
  final bool isActive;

  String get categoryLabel {
    switch (category) {
      case GiftCategory.popular:
        return 'Popular';
      case GiftCategory.luxury:
        return 'Luxury';
      case GiftCategory.exclusive:
        return 'Exclusive';
    }
  }
}

class GiftTransaction {
  const GiftTransaction({
    required this.id,
    required this.gift,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.createdAt,
    this.quantity = 1,
  });

  final String id;
  final Gift gift;
  final UserProfile sender;
  final UserProfile receiver;
  final double amount;
  final DateTime createdAt;
  final int quantity;
}
