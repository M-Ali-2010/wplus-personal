import 'user.dart';

enum StreamStatus { scheduled, live, ended }

class LiveStream {
  const LiveStream({
    required this.id,
    required this.title,
    required this.creator,
    required this.viewerCount,
    required this.status,
    this.thumbnailUrl,
    this.category,
    this.duration,
    this.likesCount = 0,
    this.giftsTotal = 0,
    this.donationsTotal = 0,
  });

  final String id;
  final String title;
  final UserProfile creator;
  final int viewerCount;
  final StreamStatus status;
  final String? thumbnailUrl;
  final String? category;
  final Duration? duration;
  final int likesCount;
  final double giftsTotal;
  final double donationsTotal;

  bool get isLive => status == StreamStatus.live;
}

class StreamComment {
  const StreamComment({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
    this.isAi = false,
    this.isGift = false,
    this.isPaid = false,
  });

  final String id;
  final UserProfile user;
  final String text;
  final DateTime createdAt;
  final bool isAi;
  final bool isGift;
  final bool isPaid;
}
