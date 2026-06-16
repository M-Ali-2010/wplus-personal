import 'package:flutter/material.dart';

import '../models/battle.dart';
import '../theme/app_colors.dart';

class BattleScoreBar extends StatelessWidget {
  const BattleScoreBar({
    super.key,
    required this.playerScore,
    required this.aiScore,
    required this.playerName,
    required this.aiName,
  });

  final int playerScore;
  final int aiScore;
  final String playerName;
  final String aiName;

  @override
  Widget build(BuildContext context) {
    final total = playerScore + aiScore;
    final ratio = total == 0 ? 0.5 : playerScore / total;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(playerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text(aiName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: (ratio * 100).round().clamp(1, 99),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF00BFFF), Color(0xFF0080FF)]),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      '$playerScore',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - ratio) * 100).round().clamp(1, 99),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '$aiScore',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BattleStatBars extends StatelessWidget {
  const BattleStatBars({super.key, required this.state});

  final BattleState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Bar(label: 'Energy', value: state.playerEnergy, color: Colors.blue)),
        const SizedBox(width: 6),
        Expanded(child: _Bar(label: 'Charisma', value: state.playerCharisma, color: AppColors.primary)),
        const SizedBox(width: 6),
        Expanded(child: _Bar(label: 'Creativity', value: state.playerCreativity, color: AppColors.secondary)),
        const SizedBox(width: 6),
        Expanded(child: _Bar(label: 'Support', value: state.playerSupport, color: AppColors.success)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            color: color,
          ),
        ),
      ],
    );
  }
}
