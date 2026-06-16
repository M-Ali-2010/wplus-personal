import 'dart:math';

import '../models/stream.dart';
import '../models/user.dart';

/// Simulates AI-generated chat messages for live streams.
/// Backend: POST /api/ai/generate-comment with stream context.
abstract final class AiCommentService {
  static final _random = Random();

  static const _botUsers = [
    UserProfile(id: 'bot1', username: 'luna_ai', displayName: 'Luna'),
    UserProfile(id: 'bot2', username: 'max_bot', displayName: 'Max'),
    UserProfile(id: 'bot3', username: 'mia_neural', displayName: 'Mia'),
    UserProfile(id: 'bot4', username: 'alex_ai', displayName: 'Alex'),
    UserProfile(id: 'bot5', username: 'zoey_bot', displayName: 'Zoey'),
    UserProfile(id: 'bot6', username: 'kai_neural', displayName: 'Kai'),
  ];

  static const _comments = [
    'This is fire! 🔥',
    'Love this vibe! 💜',
    'You\'re amazing! ✨',
    'Keep going! 🚀',
    'Best stream ever! 👑',
    'Sent you a gift! 🎁',
    'AI battle when? ⚔️',
    'This energy is unmatched! 💥',
    'Go go go! 🔥🔥',
    'Incredible content! 🌟',
    'Watching from Brazil 🇧🇷',
    'New fan here! 👋',
    'That was epic! 😍',
    'More battles please! ⚡',
    'You deserve all the gifts! 💎',
  ];

  static const _giftComments = [
    'Sent Rocket x3 🚀',
    'Sent Diamond x10 💎',
    'Sent Neon Heart 💜',
    'Sent Golden Lion 🦁',
    'Sent Flying Dragon 🐉',
  ];

  static StreamComment generate({bool includeGift = false}) {
    final user = _botUsers[_random.nextInt(_botUsers.length)];
    final text = includeGift && _random.nextBool()
        ? _giftComments[_random.nextInt(_giftComments.length)]
        : _comments[_random.nextInt(_comments.length)];

    return StreamComment(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      user: user,
      text: text,
      createdAt: DateTime.now(),
      isAi: true,
    );
  }

  static Duration randomInterval() {
    return Duration(seconds: 2 + _random.nextInt(4));
  }
}
