import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/wplus_api.dart';
import '../api/socket_service.dart';
import '../config/app_config.dart';
import '../data/mock_data.dart';
import '../models/battle.dart';
import '../models/gift.dart';
import '../models/post.dart';
import '../models/stream.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../services/ai_comment_service.dart';

// ─── App bootstrap ───────────────────────────────────────────────────────────

final appInitProvider = FutureProvider<void>((ref) async {
  if (!AppConfig.useBackend) return;
  final token = ref.watch(authTokenProvider);
  if (token == null) return;
  await ref.read(walletBalanceProvider.notifier).refresh();
});

// ─── Data providers (API or mock) ───────────────────────────────────────────

final walletProvider = FutureProvider<Wallet>((ref) async {
  if (!AppConfig.useBackend) return MockData.wallet;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchWallet();
});

final walletBalanceProvider = StateNotifierProvider<WalletBalanceNotifier, double>((ref) {
  return WalletBalanceNotifier(ref);
});

class WalletBalanceNotifier extends StateNotifier<double> {
  WalletBalanceNotifier(this._ref) : super(MockData.wallet.balance) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    if (!AppConfig.useBackend) return;
    try {
      final api = _ref.read(wplusApiProvider);
      await api.ensureLoggedIn();
      final wallet = await api.fetchWallet();
      state = wallet.balance;
    } catch (_) {}
  }

  void adjust(double delta) => state = (state + delta).clamp(0, double.infinity);

  /// Optimistic balance change. Returns rollback — call on API failure.
  VoidCallback adjustOptimistic(double delta) {
    final previous = state;
    state = (state + delta).clamp(0, double.infinity);
    return () => state = previous;
  }

  void setBalance(double balance) => state = balance;
}

final liveStreamsProvider = FutureProvider<List<LiveStream>>((ref) async {
  if (!AppConfig.useBackend) return MockData.liveStreams;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchLiveStreams();
});

final giftsProvider = FutureProvider<List<Gift>>((ref) async {
  if (!AppConfig.useBackend) return MockData.gifts;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchGifts();
});

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final mockPosts = MockData.posts;
  if (!AppConfig.useBackend) return mockPosts;

  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  final me = await api.fetchMe();
  final streams = await api.fetchLiveStreams();

  final byUsername = <String, UserProfile>{me.username: me};
  for (final stream in streams) {
    byUsername[stream.creator.username] = stream.creator;
  }

  // Map mock usernames to backend accounts
  const usernameAliases = {'niko': 'you', 'luna': 'alex'};
  return mockPosts.map((post) {
    final alias = usernameAliases[post.creator.username] ?? post.creator.username;
    final resolved = byUsername[alias];
    return resolved != null ? post.copyWith(creator: resolved) : post;
  }).toList();
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  if (!AppConfig.useBackend) return MockData.currentUser;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchMe();
});

final streamDetailProvider = FutureProvider.family<LiveStream, String>((ref, streamId) async {
  if (!AppConfig.useBackend) {
    return MockData.liveStreams.firstWhere(
      (s) => s.id == streamId,
      orElse: () => MockData.liveStreams.first,
    );
  }
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchStream(streamId);
});

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (!AppConfig.useBackend) {
    return {
      'revenue': {'total': 12450},
      'gifts': {'count': 142, 'total': 5200},
      'donations': {'count': 89, 'total': 3800},
      'paidMessages': {'count': 34, 'total': 1950},
      'streams': {'total': 12, 'live': 1, 'totalViewers': 4200},
      'availableForPayout': 9800,
    };
  }
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchDashboard();
});

final selectedGiftCategoryProvider = StateProvider<GiftCategory?>((ref) => null);

final aiBotsEnabledProvider = StateProvider<bool>((ref) => true);

final liveStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (!AppConfig.useBackend) return MockData.liveStats;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchLiveStats();
});

final aiOpponentsProvider = FutureProvider<List<AiOpponent>>((ref) async {
  if (!AppConfig.useBackend) return MockData.aiOpponents;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchAiOpponents();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  if (!AppConfig.useBackend) return MockData.leaderboard;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  final me = await api.fetchMe();
  final list = await api.fetchLeaderboard();
  return list.map((e) => LeaderboardEntry(
        rank: e.rank,
        user: e.user,
        trophies: e.trophies,
        isCurrentUser: e.user.id == me.id,
      )).toList();
});

final battleRewardsProvider = Provider<List<BattleReward>>((ref) => MockData.battleRewards);

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  if (!AppConfig.useBackend) return MockData.recentTransactions;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchTransactions();
});

final ownedGiftsProvider = StateProvider<Map<String, int>>((ref) => {
      'g3': 2,
      'g13': 5,
    });

// ─── Live Chat ───────────────────────────────────────────────────────────────

class LiveChatNotifier extends StateNotifier<List<StreamComment>> {
  LiveChatNotifier(this._ref, {this.streamId}) : super([]) {
    _init();
  }

  final Ref _ref;
  final String? streamId;
  Timer? _aiTimer;

  Future<void> _init() async {
    if (streamId == null) {
      state = List.from(MockData.streamComments);
      return;
    }

    if (AppConfig.useBackend) {
      try {
        final api = _ref.read(wplusApiProvider);
        await api.ensureLoggedIn();
        final comments = await api.fetchComments(streamId!);
        state = comments;

        final socket = _ref.read(socketServiceProvider);
        socket.onComment = (comment) => addComment(comment);
        socket.connect(streamId!);

        // joinStream called by LiveRoomScreen for livekit token
      } catch (_) {
        state = List.from(MockData.streamComments);
      }
    } else {
      state = List.from(MockData.streamComments);
    }

    if (_ref.read(aiBotsEnabledProvider)) startAiBots();
  }

  void startAiBots() {
    _aiTimer?.cancel();
    _scheduleNext();
  }

  void stopAiBots() {
    _aiTimer?.cancel();
    _aiTimer = null;
  }

  void _scheduleNext() {
    _aiTimer = Timer(AiCommentService.randomInterval(), () async {
      if (AppConfig.useBackend && streamId != null) {
        try {
          final api = _ref.read(wplusApiProvider);
          final comment = await api.generateAiComment(streamId!);
          addComment(comment);
        } catch (_) {
          addComment(AiCommentService.generate(includeGift: true));
        }
      } else {
        addComment(AiCommentService.generate(includeGift: true));
      }
      _scheduleNext();
    });
  }

  void addComment(StreamComment comment) {
    state = [...state, comment];
    if (state.length > 50) {
      state = state.sublist(state.length - 50);
    }
  }

  Future<void> addUserComment(String text, {required String displayName}) async {
    if (AppConfig.useBackend && streamId != null) {
      try {
        final api = _ref.read(wplusApiProvider);
        final comment = await api.postComment(streamId!, text);
        addComment(comment);
        return;
      } catch (_) {}
    }
    addComment(StreamComment(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      user: MockData.currentUser.copyWith(displayName: displayName),
      text: text,
      createdAt: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    if (streamId != null) {
      _ref.read(socketServiceProvider).disconnect();
    }
    super.dispose();
  }
}

final liveChatProvider =
    StateNotifierProvider.family<LiveChatNotifier, List<StreamComment>, String?>(
  (ref, streamId) {
    final notifier = LiveChatNotifier(ref, streamId: streamId);
    ref.listen(aiBotsEnabledProvider, (prev, enabled) {
      if (enabled) {
        notifier.startAiBots();
      } else {
        notifier.stopAiBots();
      }
    });
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);

// ─── Battle ──────────────────────────────────────────────────────────────────

class BattleNotifier extends StateNotifier<BattleState?> {
  BattleNotifier(this._ref) : super(null);

  final Ref _ref;
  Timer? _timer;
  Timer? _syncTimer;

  void startBattle(AiOpponent opponent, BattleMode mode, {String? battleId, String? streamId}) {
    final rounds = mode == BattleMode.classic ? 3 : 1;
    final seconds = mode == BattleMode.speed ? 60 : 45;

    state = BattleState(
      opponent: opponent,
      mode: mode,
      battleId: battleId,
      streamId: streamId,
      totalRounds: rounds,
      secondsLeft: seconds,
    );
    _startTimer();
    _startScoreSync();
  }

  void _startScoreSync() {
    _syncTimer?.cancel();
    if (!AppConfig.useBackend || state?.battleId == null) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) => _syncScore());
  }

  Future<void> _syncScore() async {
    if (state == null || state!.battleId == null) return;
    try {
      final api = _ref.read(wplusApiProvider);
      await api.updateBattleScore(state!.battleId!, state!.playerScore, state!.aiScore);
    } catch (_) {}
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == null || !state!.isActive) return;
      if (state!.secondsLeft <= 1) {
        _endRound();
      } else {
        state = state!.copyWith(secondsLeft: state!.secondsLeft - 1);
      }
    });
  }

  void addPlayerPoints(int points) {
    if (state == null) return;
    state = state!.copyWith(playerScore: state!.playerScore + points);
  }

  void addAiPoints(int points) {
    if (state == null) return;
    state = state!.copyWith(aiScore: state!.aiScore + points);
  }

  void boostPlayer() {
    addPlayerPoints(50);
    if (state != null) {
      state = state!.copyWith(
        playerSupport: (state!.playerSupport + 5).clamp(0, 100),
        playerEnergy: (state!.playerEnergy + 3).clamp(0, 100),
      );
    }
  }

  void _endRound() {
    if (state == null) return;
    final playerWon = state!.playerScore >= state!.aiScore;

    if (state!.currentRound >= state!.totalRounds) {
      state = state!.copyWith(isActive: false, secondsLeft: 0);
      _timer?.cancel();
      _syncTimer?.cancel();
      _finishBattle();
      return;
    }

    state = state!.copyWith(
      currentRound: state!.currentRound + 1,
      secondsLeft: state!.mode == BattleMode.speed ? 60 : 45,
      playerWinStreak: playerWon ? state!.playerWinStreak + 1 : 0,
      aiWinStreak: playerWon ? 0 : state!.aiWinStreak + 1,
      playerScore: 0,
      aiScore: 0,
    );
  }

  Future<void> _finishBattle() async {
    if (state == null || state!.battleId == null || !AppConfig.useBackend) return;
    try {
      final api = _ref.read(wplusApiProvider);
      await api.endBattle(state!.battleId!);
    } catch (_) {}
  }

  void endBattle() {
    _timer?.cancel();
    _syncTimer?.cancel();
    _finishBattle();
    state = state?.copyWith(isActive: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}

final battleProvider = StateNotifierProvider<BattleNotifier, BattleState?>((ref) => BattleNotifier(ref));
