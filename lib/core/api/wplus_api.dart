import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/battle.dart';
import '../models/gift.dart';
import '../models/stream.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import 'api_client.dart';

final wplusApiProvider = Provider<WPlusApi>((ref) {
  return WPlusApi(ref.watch(apiClientProvider), ref);
});

class WPlusApi {
  WPlusApi(this._dio, this._ref);

  final Dio _dio;
  final Ref _ref;
  final _uuid = const Uuid();

  String get idempotencyKey => _uuid.v4();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = res.data['accessToken'] as String;
    await _ref.read(authTokenProvider.notifier).setToken(token);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
    bool asCreator = false,
  }) async {
    final res = await _dio.post('/api/auth/register', data: {
      'email': email,
      'username': username,
      'password': password,
      if (displayName != null) 'displayName': displayName,
      'asCreator': asCreator,
    });
    final token = res.data['accessToken'] as String;
    await _ref.read(authTokenProvider.notifier).setToken(token);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> logout() async {
    await _ref.read(authTokenProvider.notifier).clear();
  }

  Future<void> ensureLoggedIn() async {
    if (_ref.read(authTokenProvider) != null) return;
    if (!AppConfig.useBackend) return;
    throw StateError('Not authenticated — please sign in');
  }

  Future<UserProfile> fetchMe() async {
    final res = await _dio.get('/api/auth/me');
    final data = res.data as Map<String, dynamic>;
    return _mapUser(data['user'] as Map<String, dynamic>);
  }

  Future<LiveStream> fetchStream(String streamId) async {
    final res = await _dio.get('/api/streams/$streamId');
    return _mapStream(res.data as Map<String, dynamic>);
  }

  Future<List<Gift>> fetchGifts() async {
    final res = await _dio.get('/api/gifts');
    final list = res.data as List;
    return list.map((g) => _mapGift(g as Map<String, dynamic>)).toList();
  }

  Future<List<LiveStream>> fetchLiveStreams() async {
    final res = await _dio.get('/api/streams/live');
    final list = res.data as List;
    return list.map((s) => _mapStream(s as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchLiveStats() async {
    final res = await _dio.get('/api/streams/stats');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Wallet> fetchWallet() async {
    final res = await _dio.get('/api/wallet');
    final data = res.data as Map<String, dynamic>;
    return Wallet(
      balance: (data['balance'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'W',
      pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<List<Transaction>> fetchTransactions() async {
    final res = await _dio.get('/api/wallet/transactions');
    final list = res.data as List;
    return list.map((t) => _mapTransaction(t as Map<String, dynamic>)).toList();
  }

  Future<double> topUp(double amount) async {
    final res = await _dio.post('/api/wallet/topup', data: {
      'amount': amount,
      'idempotencyKey': idempotencyKey,
    });
    final wallet = res.data['wallet'] as Map<String, dynamic>;
    return (wallet['balance'] as num).toDouble();
  }

  Future<void> sendGift({
    required String giftId,
    required String receiverId,
    String? streamId,
    int quantity = 1,
  }) async {
    await _dio.post('/api/gifts/send', data: {
      'giftId': giftId,
      'receiverId': receiverId,
      'streamId': streamId,
      'quantity': quantity,
      'idempotencyKey': idempotencyKey,
    });
  }

  Future<void> sendDonation({
    required String receiverId,
    required double amount,
    String? streamId,
    String? postId,
    String? message,
  }) async {
    await _dio.post('/api/donations', data: {
      'receiverId': receiverId,
      'amount': amount,
      'streamId': streamId,
      'postId': postId,
      'message': message,
      'idempotencyKey': idempotencyKey,
    });
  }

  Future<Map<String, dynamic>> createStream({
    required String title,
    String? category,
    bool aiEnabled = false,
  }) async {
    final res = await _dio.post('/api/streams', data: {
      'title': title,
      'category': category,
      'aiEnabled': aiEnabled,
      'giftsEnabled': true,
      'donationsEnabled': true,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> startStream(String streamId) async {
    final res = await _dio.post('/api/streams/$streamId/start');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> joinStream(String streamId) async {
    final res = await _dio.post('/api/streams/$streamId/join');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<StreamComment> postComment(String streamId, String text) async {
    final res = await _dio.post('/api/streams/$streamId/comments', data: {'text': text});
    return _mapComment(res.data as Map<String, dynamic>);
  }

  Future<List<StreamComment>> fetchComments(String streamId) async {
    final res = await _dio.get('/api/streams/$streamId/comments');
    final list = res.data as List;
    return list.map((c) => _mapComment(c as Map<String, dynamic>)).toList();
  }

  Future<StreamComment> generateAiComment(String streamId) async {
    final res = await _dio.post('/api/ai/generate-comment', data: {
      'streamId': streamId,
      'includeGift': true,
    });
    return _mapComment(res.data as Map<String, dynamic>);
  }

  Future<List<AiOpponent>> fetchAiOpponents() async {
    final res = await _dio.get('/api/battles/opponents');
    final list = res.data as List;
    return list.map((o) => _mapOpponent(o as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> startBattle({
    required String streamId,
    required String opponentId,
    required BattleMode mode,
  }) async {
    final res = await _dio.post('/api/battles/start', data: {
      'streamId': streamId,
      'opponentId': opponentId,
      'mode': mode.name,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> updateBattleScore(String battleId, int playerScore, int aiScore) async {
    await _dio.post('/api/battles/$battleId/score', data: {
      'playerScore': playerScore,
      'aiScore': aiScore,
    });
  }

  Future<void> endBattle(String battleId, {String? winnerId}) async {
    await _dio.post('/api/battles/$battleId/end', data: {
      if (winnerId != null) 'winnerId': winnerId,
    });
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final res = await _dio.get('/api/battles/leaderboard');
    final list = res.data as List;
    return list.map((e) {
      final user = e['user'] as Map<String, dynamic>;
      return LeaderboardEntry(
        rank: e['rank'] as int,
        user: _mapUser(user),
        trophies: (e['trophies'] as num).toInt(),
        isCurrentUser: false,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> fetchDashboard() async {
    final res = await _dio.get('/api/dashboard');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> sendPaidMessage({
    required String receiverId,
    required String text,
    required double amount,
    String? streamId,
    String? postId,
  }) async {
    await _dio.post('/api/paid-messages', data: {
      'receiverId': receiverId,
      'text': text,
      'amount': amount,
      'streamId': streamId,
      'postId': postId,
      'idempotencyKey': idempotencyKey,
    });
  }

  Future<bool> checkSubscription(String creatorId) async {
    final res = await _dio.get('/api/subscriptions/check/$creatorId');
    return res.data as bool;
  }

  Future<void> subscribe(String creatorId, {String tier = 'premium'}) async {
    await _dio.post('/api/subscriptions/subscribe', data: {
      'creatorId': creatorId,
      'tier': tier,
      'idempotencyKey': idempotencyKey,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPremiumPosts({String? creatorId}) async {
    final res = await _dio.get(
      '/api/subscriptions/premium-posts',
      queryParameters: creatorId != null ? {'creatorId': creatorId} : null,
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> purchasePremiumPost(String postId) async {
    final res = await _dio.post('/api/subscriptions/premium-posts/$postId/purchase', data: {
      'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getLivekitToken(String streamId, {bool isPublisher = false}) async {
    final endpoint = isPublisher
        ? '/api/streams/$streamId/start'
        : '/api/streams/$streamId/join';
    final res = await _dio.post(endpoint);
    final data = res.data as Map<String, dynamic>;
    return Map<String, dynamic>.from(data['livekit'] as Map? ?? {});
  }

  // ─── Marketplace ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchJobs({String? category}) async {
    final res = await _dio.get(
      '/api/marketplace/jobs',
      queryParameters: category != null ? {'category': category} : null,
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> fetchJob(String jobId) async {
    final res = await _dio.get('/api/marketplace/jobs/$jobId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String category,
    required double budget,
    String? currency,
    List<String>? tags,
  }) async {
    final res = await _dio.post('/api/marketplace/jobs', data: {
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'currency': currency ?? 'W',
      if (tags != null) 'tags': tags,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> applyJob(String jobId, {String? coverLetter}) async {
    await _dio.post('/api/marketplace/jobs/$jobId/apply', data: {
      if (coverLetter != null) 'coverLetter': coverLetter,
    });
  }

  // ─── Moderation ────────────────────────────────────────────────────────────

  Future<void> muteUser(String streamId, String userId) async {
    await _dio.post('/api/streams/$streamId/mute', data: {'userId': userId});
  }

  Future<void> banUser(String streamId, String userId) async {
    await _dio.post('/api/streams/$streamId/ban', data: {'userId': userId});
  }

  Gift _mapGift(Map<String, dynamic> g) {
    return Gift(
      id: g['id'] as String,
      title: g['title'] as String,
      price: (g['price'] as num).toDouble(),
      category: GiftCategory.values.firstWhere(
        (c) => c.name == (g['category'] as String? ?? 'popular'),
        orElse: () => GiftCategory.popular,
      ),
      assetType: GiftAssetType.values.firstWhere(
        (a) => a.name == (g['assetType'] as String? ?? 'gif'),
        orElse: () => GiftAssetType.gif,
      ),
      emoji: g['emoji'] as String? ?? '🎁',
    );
  }

  LiveStream _mapStream(Map<String, dynamic> s) {
    final creator = s['creator'] as Map<String, dynamic>? ?? {};
    return LiveStream(
      id: s['id'] as String,
      title: s['title'] as String,
      creator: _mapUser(creator),
      viewerCount: (s['viewerCount'] as num?)?.toInt() ?? 0,
      status: StreamStatus.values.firstWhere(
        (st) => st.name == (s['status'] as String? ?? 'live'),
        orElse: () => StreamStatus.live,
      ),
      category: s['category'] as String?,
      thumbnailUrl: s['thumbnailUrl'] as String?,
      likesCount: (s['likesCount'] as num?)?.toInt() ?? 0,
      giftsTotal: (s['giftsTotal'] as num?)?.toDouble() ?? 0,
      donationsTotal: (s['donationsTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  UserProfile _mapUser(Map<String, dynamic> u) {
    return UserProfile(
      id: u['id'] as String? ?? '',
      username: u['username'] as String? ?? '',
      displayName: u['displayName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == (u['role'] as String? ?? 'user'),
        orElse: () => UserRole.user,
      ),
      isVerified: u['isVerified'] as bool? ?? false,
      followersCount: (u['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (u['followingCount'] as num?)?.toInt() ?? 0,
      bio: u['bio'] as String?,
    );
  }

  StreamComment _mapComment(Map<String, dynamic> c) {
    return StreamComment(
      id: c['id'] as String,
      user: _mapUser(c['user'] as Map<String, dynamic>? ?? {}),
      text: c['text'] as String,
      createdAt: DateTime.parse(c['createdAt'] as String),
      isAi: c['isAi'] as bool? ?? false,
      isGift: c['isGift'] as bool? ?? false,
      isPaid: c['isPaid'] as bool? ?? false,
    );
  }

  Transaction _mapTransaction(Map<String, dynamic> t) {
    return Transaction(
      id: t['id'] as String,
      type: TransactionType.values.firstWhere(
        (ty) => ty.name == (t['type'] as String),
        orElse: () => TransactionType.topup,
      ),
      amount: (t['amount'] as num).toDouble(),
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == (t['status'] as String),
        orElse: () => TransactionStatus.completed,
      ),
      createdAt: DateTime.parse(t['createdAt'] as String),
      counterpartyName: t['counterpartyName'] as String?,
      description: t['description'] as String?,
    );
  }

  AiOpponent _mapOpponent(Map<String, dynamic> o) {
    return AiOpponent(
      id: o['id'] as String,
      name: o['name'] as String,
      tagline: o['tagline'] as String? ?? '',
      difficulty: BattleDifficulty.values.firstWhere(
        (d) => d.name == (o['difficulty'] as String? ?? 'medium'),
        orElse: () => BattleDifficulty.medium,
      ),
      winRate: (o['winRate'] as num?)?.toInt() ?? 50,
      emoji: o['emoji'] as String? ?? '🤖',
      colorHex: int.tryParse(o['colorHex']?.toString().replaceFirst('0x', '0x') ?? '0xFF00FFFF') ?? 0xFF00FFFF,
    );
  }
}
