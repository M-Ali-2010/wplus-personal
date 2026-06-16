import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/api/wplus_api.dart';
import '../../core/models/gift.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/battle_widgets.dart';
import '../../core/widgets/live_chat_panel.dart';
import '../../core/widgets/wplus_widgets.dart';
import '../gifts/gift_picker_sheet.dart';

class BattleRoomScreen extends ConsumerStatefulWidget {
  const BattleRoomScreen({super.key});

  @override
  ConsumerState<BattleRoomScreen> createState() => _BattleRoomScreenState();
}

class _BattleRoomScreenState extends ConsumerState<BattleRoomScreen> {
  final _commentController = TextEditingController();
  final List<String> _giftAnimations = [];
  Timer? _aiScoreTimer;

  @override
  void initState() {
    super.initState();
    _aiScoreTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final battle = ref.read(battleProvider);
      if (battle != null && battle.isActive) {
        ref.read(battleProvider.notifier).addAiPoints(10 + (battle.currentRound * 5));
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _aiScoreTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battle = ref.watch(battleProvider);
    final chatStreamId = battle?.streamId;
    final comments = ref.watch(liveChatProvider(chatStreamId));
    final balance = ref.watch(walletBalanceProvider);

    if (battle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle')),
        body: const Center(child: Text('No active battle')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _BattleSide(name: 'You', emoji: '🎤', isPlayer: true)),
                    Container(
                      width: 60,
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _BattleSide(
                        name: battle.opponent.name,
                        emoji: battle.opponent.emoji,
                        isPlayer: false,
                        color: Color(battle.opponent.colorHex),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StreakBadge(label: 'Win Streak', value: battle.playerWinStreak),
                        Column(
                          children: [
                            Text(
                              'Round ${battle.currentRound}/${battle.totalRounds}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '00:${battle.secondsLeft.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                          ],
                        ),
                        _StreakBadge(label: 'AI Streak', value: battle.aiWinStreak),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BattleScoreBar(
                      playerScore: battle.playerScore,
                      aiScore: battle.aiScore,
                      playerName: 'You',
                      aiName: battle.opponent.name,
                    ),
                    const SizedBox(height: 10),
                    BattleStatBars(state: battle),
                  ],
                ),
              ),
            ],
          ),

          // Gift animations
          ..._giftAnimations.map((emoji) => Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) => Opacity(
                    opacity: 1 - value,
                    child: Transform.scale(scale: 1 + value * 2, child: Text(emoji, style: const TextStyle(fontSize: 80))),
                  ),
                ),
              )),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      ref.read(battleProvider.notifier).endBattle();
                      context.pop();
                    },
                  ),
                  const LiveBadge(viewerCount: 1200),
                  const Spacer(),
                  WCoinBadge(amount: balance, compact: true),
                ],
              ),
            ),
          ),

          // Chat overlay
          Positioned(
            left: 0,
            right: 80,
            bottom: 200,
            child: LiveChatPanel(comments: comments, maxHeight: 100),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.black.withValues(alpha: 0)],
                  ),
                ),
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
                        onSubmitted: (text) {
                          if (text.trim().isEmpty) return;
                          ref.read(liveChatProvider(chatStreamId).notifier).addUserComment(text.trim(), displayName: 'You');
                          _commentController.clear();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.card_giftcard, color: AppColors.primary),
                      onPressed: () => showGiftPicker(context, onSend: _sendGift),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bolt, color: AppColors.warning),
                      tooltip: 'Boost',
                      onPressed: () {
                        ref.read(battleProvider.notifier).boostPlayer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('+50 points! Boost activated'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (!battle.isActive)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      battle.playerScore >= battle.aiScore ? 'You Win!' : '${battle.opponent.name} Wins!',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back to Battles'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendGift(Gift gift) async {
    final balance = ref.read(walletBalanceProvider);
    if (balance < gift.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance'), backgroundColor: AppColors.error),
      );
      return;
    }

    final battle = ref.read(battleProvider);
    final streamId = battle?.streamId;

    if (AppConfig.useBackend && streamId != null) {
      try {
        final api = ref.read(wplusApiProvider);
        await api.ensureLoggedIn();
        final me = await api.fetchMe();
        await api.sendGift(
          giftId: gift.id,
          receiverId: me.id,
          streamId: streamId,
        );
        await ref.read(walletBalanceProvider.notifier).refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gift failed: $e'), backgroundColor: AppColors.error),
          );
        }
        return;
      }
    } else {
      ref.read(walletBalanceProvider.notifier).adjustOptimistic(-gift.price);
    }

    ref.read(battleProvider.notifier).addPlayerPoints(gift.price ~/ 5);
    setState(() => _giftAnimations.add(gift.emoji));
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _giftAnimations.remove(gift.emoji));
    });
  }
}

class _BattleSide extends StatelessWidget {
  const _BattleSide({
    required this.name,
    required this.emoji,
    required this.isPlayer,
    this.color,
  });

  final String name;
  final String emoji;
  final bool isPlayer;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isPlayer ? Alignment.topLeft : Alignment.topRight,
          end: Alignment.bottomCenter,
          colors: [
            (color ?? AppColors.secondary).withValues(alpha: 0.15),
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (isPlayer)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning)),
      ],
    );
  }
}
