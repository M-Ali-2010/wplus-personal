import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/api/wplus_api.dart';
import '../../core/api/socket_service.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/gift.dart';
import '../../core/models/stream.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/live_chat_panel.dart';
import '../../core/widgets/live_stats_bar.dart';
import '../../core/widgets/wplus_widgets.dart';
import '../../core/widgets/gift_animation_widget.dart';
import '../../core/widgets/stream_video_view.dart';
import '../donate/donate_sheet.dart';
import '../gifts/gift_picker_sheet.dart';
import '../messages/paid_message_sheet.dart';

class LiveRoomScreen extends ConsumerStatefulWidget {
  const LiveRoomScreen({
    super.key,
    required this.streamId,
    // Передаётся из start_live_screen когда creator запускает стрим
    // Содержит { token, url, room, isStub } — creator подключается как publisher
    this.publisherLivekit,
  });

  final String streamId;
  final Map<String, dynamic>? publisherLivekit;

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  final _commentController = TextEditingController();
  final List<Gift> _giftAnimations = [];
  final List<_FloatingHeart> _hearts = [];
  int? _viewerCountOverride;
  Map<String, dynamic>? _livekit;
  // true когда это creator (publisher), false когда viewer
  bool _isPublisher = false;

  @override
  void initState() {
    super.initState();

    // Если пришёл publisherLivekit — мы creator, сразу ставим данные
    if (widget.publisherLivekit != null) {
      _livekit = widget.publisherLivekit;
      _isPublisher = true;
    }

    if (AppConfig.useBackend && widget.streamId != 'new') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupSocket();
        // Viewer подгружает livekit токен — creator уже имеет его из extra
        if (!_isPublisher) _loadLivekit();
      });
    }
  }

  Future<void> _loadLivekit() async {
    try {
      final api = ref.read(wplusApiProvider);
      final join = await api.joinStream(widget.streamId);
      final lk = join['livekit'] as Map<String, dynamic>?;
      if (mounted && lk != null) setState(() => _livekit = lk);
    } catch (_) {}
  }

  // joinStream вызывается только для viewer; creator получает токен через publisherLivekit

  void _showModMenu(String userId, String displayName) {
    if (!_isPublisher) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Moderate: $displayName', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.mic_off, color: AppColors.warning),
              title: const Text('Mute User'),
              subtitle: const Text('Prevent from sending messages'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final api = ref.read(wplusApiProvider);
                  await api.muteUser(widget.streamId, userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$displayName muted'), backgroundColor: AppColors.warning),
                    );
                  }
                } catch (_) {}
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: const Text('Ban User'),
              subtitle: const Text('Remove from stream permanently'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final api = ref.read(wplusApiProvider);
                  await api.banUser(widget.streamId, userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$displayName banned'), backgroundColor: AppColors.error),
                    );
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _setupSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.addGiftListener((data) {
      final emoji = data['giftEmoji'] as String? ?? data['emoji'] as String? ?? '🎁';
      final gift = Gift(
        id: data['giftId'] as String? ?? 'remote',
        title: data['giftTitle'] as String? ?? 'Gift',
        price: (data['amount'] as num?)?.toDouble() ?? 10,
        category: GiftCategory.popular,
        assetType: GiftAssetType.gif,
        emoji: emoji,
      );
      if (mounted) setState(() => _giftAnimations.add(gift));
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted && _giftAnimations.isNotEmpty) {
          setState(() => _giftAnimations.removeAt(0));
        }
      });
    });
    socket.onDonation = (data) {
      if (!mounted) return;
      final amount = (data['amount'] as num?)?.toInt() ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💜 Donation: $amount W'), backgroundColor: AppColors.success),
      );
    };
    socket.onViewerCount = (count) {
      if (mounted) setState(() => _viewerCountOverride = count);
    };
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewStream = widget.streamId == 'new';

    if (!isNewStream && AppConfig.useBackend) {
      final streamAsync = ref.watch(streamDetailProvider(widget.streamId));
      return streamAsync.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Live')),
          body: Center(child: Text('Failed to load stream: $e')),
        ),
        data: (stream) => _buildRoom(stream, isNewStream: false),
      );
    }

    final stream = isNewStream
        ? LiveStream(
      id: 'new',
      title: 'My Live Stream',
      creator: MockData.currentUser,
      viewerCount: 128,
      status: StreamStatus.live,
      category: 'Live',
      likesCount: 0,
    )
        : MockData.liveStreams.firstWhere(
          (s) => s.id == widget.streamId,
      orElse: () => MockData.liveStreams.first,
    );

    return _buildRoom(stream, isNewStream: isNewStream);
  }

  Widget _buildRoom(LiveStream stream, {required bool isNewStream}) {
    final viewerCount = _viewerCountOverride ?? stream.viewerCount;
    final comments = ref.watch(liveChatProvider(widget.streamId));
    final balance = ref.watch(walletBalanceProvider);
    final aiBots = ref.watch(aiBotsEnabledProvider);
    final stats = ref.watch(liveStatsProvider).maybeWhen(
      data: (s) => s,
      orElse: () => MockData.liveStats,
    );
    final giftsAsync = ref.watch(giftsProvider);
    final quickGifts = giftsAsync.maybeWhen(
      data: (g) => g.take(4).toList(),
      orElse: () => MockData.gifts.take(4).toList(),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // Обязательно, чтобы инпут не ломался при открытии клавиатуры
      body: Stack(
        children: [
          // 1. ВИДЕОСТРИМ ИЛИ ЗАГЛУШКА
          Positioned.fill(
            child: _livekit != null
                ? StreamVideoView(
              token: _livekit!['token'] as String? ?? '',
              url: _livekit!['url'] as String? ?? '',
              room: _livekit!['room'] as String? ?? '',
              isStub: _livekit!['isStub'] as bool? ?? true,
              canPublish: false,
            )
                : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surfaceLight, Colors.black],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        stream.creator.displayName[0],
                        style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(stream.creator.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(stream.title, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),

          // 2. АНИМАЦИИ (Сердечки и Подарки)
          ..._hearts.map((h) => Positioned(
            right: 16,
            bottom: 180 + h.offset,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 2000),
              builder: (context, value, child) => Opacity(
                opacity: 1 - value,
                child: Transform.translate(
                  offset: Offset(0, -80 * value),
                  child: Text(h.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          )),
          ..._giftAnimations.map((gift) => Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) => GiftAnimationWidget(
                gift: gift,
                opacity: 1 - value,
                scale: 1 + value * 2,
              ),
            ),
          )),

          // 3. ВЕРХНЯЯ ПАНЕЛЬ (Навигация, Инфо профиля, Статус)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ряд 1: Кнопка назад, бейджи, монеты
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
                        LiveBadge(viewerCount: viewerCount),
                        const Spacer(),
                        WCoinBadge(amount: balance, compact: true),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(aiBots ? Icons.smart_toy : Icons.smart_toy_outlined, color: aiBots ? AppColors.secondary : Colors.white54),
                          tooltip: 'AI Chat Bots',
                          onPressed: () => ref.read(aiBotsEnabledProvider.notifier).state = !aiBots,
                        ),
                        IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Ряд 2: Плашка стримера + Battle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(24)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                                  child: Text(stream.creator.displayName[0], style: const TextStyle(fontSize: 12, color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                Expanded( // Исправляет сплющивание текста
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              stream.creator.displayName,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (stream.creator.isVerified) ...[const SizedBox(width: 4), const VerifiedBadge(size: 12)],
                                        ],
                                      ),
                                      Text('${formatCount(stream.likesCount)} likes', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(16)),
                                  child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isNewStream) const SizedBox(width: 8),
                        if (isNewStream)
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.battleSetup),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Battle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Статус LIVE
                    if (isNewStream)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🔴 You are LIVE', style: TextStyle(color: AppColors.success, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 4. БЫСТРЫЕ ПОДАРКИ СБОКУ
          Positioned(
            right: 8,
            bottom: 200,
            child: Column(
              children: quickGifts.map((gift) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _sendGift(gift, stream),
                    child: Container(
                      width: 48,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Text(gift.emoji, style: const TextStyle(fontSize: 20)),
                          Text('${gift.price.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 5. НИЖНЯЯ ПАНЕЛЬ (Чат, Инпут, Действия)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiveChatPanel(
                      comments: comments,
                      maxHeight: 140,
                      onLongPressUser: _isPublisher ? _showModMenu : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Say something...',
                                hintStyle: const TextStyle(color: AppColors.textMuted),
                                filled: true,
                                fillColor: Colors.white12,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onSubmitted: _sendComment,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.diamond_outlined, color: AppColors.secondary),
                            tooltip: 'Paid Message',
                            onPressed: () => showPaidMessageSheet(
                              context,
                              receiverId: stream.creator.id,
                              creatorName: stream.creator.displayName,
                              streamId: widget.streamId == 'new' ? null : widget.streamId,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite, color: AppColors.live),
                            onPressed: _addHeart,
                          ),
                          IconButton(
                            icon: const Icon(Icons.card_giftcard, color: AppColors.primary),
                            onPressed: () => showGiftPicker(context, onSend: (g) => _sendGift(g, stream)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volunteer_activism, color: AppColors.accent),
                            onPressed: () => showDonateSheet(
                              context,
                              creatorName: stream.creator.displayName,
                              onDonate: (amount) => _sendDonation(stream.creator.id, amount),
                            ),
                          ),
                        ],
                      ),
                    ),
                    LiveStatsBar(stats: stats),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _sendComment(String text) {
    if (text.trim().isEmpty) return;
    ref.read(liveChatProvider(widget.streamId).notifier).addUserComment(text.trim(), displayName: 'You');
    _commentController.clear();
  }

  void _addHeart() {
    setState(() {
      _hearts.add(_FloatingHeart('❤️', _hearts.length * 20.0));
    });
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted && _hearts.isNotEmpty) setState(() => _hearts.removeAt(0));
    });
  }

  Future<void> _sendGift(Gift gift, LiveStream stream) async {
    final balance = ref.read(walletBalanceProvider);
    if (balance < gift.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance — top up W coins'), backgroundColor: AppColors.error),
      );
      return;
    }

    final streamId = widget.streamId == 'new' ? null : widget.streamId;

    if (AppConfig.useBackend && streamId != null) {
      try {
        final api = ref.read(wplusApiProvider);
        await api.sendGift(
          giftId: gift.id,
          receiverId: stream.creator.id,
          streamId: streamId,
        );
        await ref.read(walletBalanceProvider.notifier).refresh();
        ref.invalidate(transactionsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gift failed: $e'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
    } else {
      final rollback = ref.read(walletBalanceProvider.notifier).adjustOptimistic(-gift.price);
      try {
        // mock mode — no API
      } catch (_) {
        rollback();
        return;
      }
    }

    setState(() => _giftAnimations.add(gift));
    ref.read(liveChatProvider(widget.streamId).notifier).addUserComment('Sent ${gift.title} x1', displayName: 'You');
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _giftAnimations.contains(gift)) {
        setState(() => _giftAnimations.remove(gift));
      }
    });
  }

  Future<void> _sendDonation(String receiverId, double amount) async {
    final streamId = widget.streamId == 'new' ? null : widget.streamId;

    if (AppConfig.useBackend) {
      try {
        final api = ref.read(wplusApiProvider);
        await api.sendDonation(
          receiverId: receiverId,
          amount: amount,
          streamId: streamId,
        );
        await ref.read(walletBalanceProvider.notifier).refresh();
        ref.invalidate(transactionsProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Donation failed: $e'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
    } else {
      final rollback = ref.read(walletBalanceProvider.notifier).adjustOptimistic(-amount);
      try {
        // mock mode
      } catch (_) {
        rollback();
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donated ${amount.toInt()} W 💜'), backgroundColor: AppColors.success),
      );
    }
  }
}

class _FloatingHeart {
  _FloatingHeart(this.emoji, this.offset);
  final String emoji;
  final double offset;
}