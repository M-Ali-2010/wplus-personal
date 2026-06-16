import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/api/wplus_api.dart';
import '../../core/models/battle.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class BattleSetupScreen extends ConsumerStatefulWidget {
  const BattleSetupScreen({super.key});

  @override
  ConsumerState<BattleSetupScreen> createState() => _BattleSetupScreenState();
}

class _BattleSetupScreenState extends ConsumerState<BattleSetupScreen> {
  AiOpponent? _selectedOpponent;
  BattleMode _selectedMode = BattleMode.classic;
  bool _loading = false;

  Future<void> _startBattle() async {
    if (_selectedOpponent == null) return;
    setState(() => _loading = true);
    try {
      if (AppConfig.useBackend) {
        final api = ref.read(wplusApiProvider);
        await api.ensureLoggedIn();
        final stream = await api.createStream(
          title: 'AI Battle vs ${_selectedOpponent!.name}',
          category: 'AI Battle',
          aiEnabled: true,
        );
        final started = await api.startStream(stream['id'] as String);
        final streamId = started['stream']?['id'] as String? ?? stream['id'] as String;
        final result = await api.startBattle(
          streamId: streamId,
          opponentId: _selectedOpponent!.id,
          mode: _selectedMode,
        );
        ref.read(battleProvider.notifier).startBattle(
              _selectedOpponent!,
              _selectedMode,
              battleId: result['battleId'] as String?,
              streamId: streamId,
            );
      } else {
        ref.read(battleProvider.notifier).startBattle(_selectedOpponent!, _selectedMode);
      }
      if (mounted) context.push(AppRoutes.battleRoom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start battle: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opponentsAsync = ref.watch(aiOpponentsProvider);

    return opponentsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (opponents) => Scaffold(
      appBar: AppBar(
        title: const Text('AI Battles'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.leaderboard),
            child: const Text('Leaderboard'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
            child: const Text(
              'Compete with AI. Entertain your audience.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'TikTok-style battles with smart AI opponents, gifts and live voting.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          const Text('Battle Modes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _ModeCard(
            title: 'Classic Battle',
            subtitle: 'Best of 3 rounds',
            icon: Icons.emoji_events,
            selected: _selectedMode == BattleMode.classic,
            onTap: () => setState(() => _selectedMode = BattleMode.classic),
          ),
          _ModeCard(
            title: 'Speed Battle',
            subtitle: '60-second intense rounds',
            icon: Icons.speed,
            selected: _selectedMode == BattleMode.speed,
            onTap: () => setState(() => _selectedMode = BattleMode.speed),
          ),
          _ModeCard(
            title: 'Survival Battle',
            subtitle: 'Last one standing',
            icon: Icons.shield,
            selected: _selectedMode == BattleMode.survival,
            onTap: () => setState(() => _selectedMode = BattleMode.survival),
          ),
          const SizedBox(height: 24),
          const Text('Choose AI Opponent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...opponents.map((opponent) => _OpponentCard(
                opponent: opponent,
                selected: _selectedOpponent?.id == opponent.id,
                onChallenge: () => setState(() => _selectedOpponent = opponent),
              )),
          const SizedBox(height: 24),
          GradientButton(
            label: _loading ? 'STARTING...' : 'START BATTLE',
            icon: Icons.flash_on,
            expanded: true,
            onPressed: _selectedOpponent == null || _loading ? null : _startBattle,
          ),
        ],
      ),
    ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.gradientPrimary : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.transparent : AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : null)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: selected ? Colors.white70 : AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.opponent,
    required this.selected,
    required this.onChallenge,
  });

  final AiOpponent opponent;
  final bool selected;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(opponent.colorHex).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(opponent.emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(opponent.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(opponent.difficultyLabel, style: const TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
                Text(opponent.tagline, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text('Win Rate: ${opponent.winRate}%', style: const TextStyle(color: AppColors.primary, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onChallenge,
            style: ElevatedButton.styleFrom(
              backgroundColor: selected ? AppColors.success : AppColors.primary,
            ),
            child: Text(selected ? 'Selected' : 'Challenge'),
          ),
        ],
      ),
    );
  }
}
