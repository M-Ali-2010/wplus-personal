import 'user.dart';

class Post {
  const Post({
    required this.id,
    required this.creator,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.likesCount = 0,
    this.donationsCount = 0,
    this.donationsTotal = 0,
    this.isPremium = false,
  });

  final String id;
  final UserProfile creator;
  final String content;
  final DateTime createdAt;
  final String? imageUrl;
  final int likesCount;
  final int donationsCount;
  final double donationsTotal;
  final bool isPremium;

  Post copyWith({UserProfile? creator}) {
    return Post(
      id: id,
      creator: creator ?? this.creator,
      content: content,
      createdAt: createdAt,
      imageUrl: imageUrl,
      likesCount: likesCount,
      donationsCount: donationsCount,
      donationsTotal: donationsTotal,
      isPremium: isPremium,
    );
  }
}
