import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/wplus_widgets.dart';

class LiveStatsBar extends StatelessWidget {
  const LiveStatsBar({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(icon: Icons.visibility, label: 'Viewers', value: formatCount((stats['viewers'] as num?)?.toInt() ?? 0), color: AppColors.primary),
          _Stat(icon: Icons.chat_bubble_outline, label: 'Chats', value: formatCount((stats['chats'] as num?)?.toInt() ?? 0), color: AppColors.secondary),
          _Stat(icon: Icons.public, label: 'Countries', value: '${(stats['countries'] as num?)?.toInt() ?? 0}+', color: AppColors.accent),
          _Stat(icon: Icons.favorite, label: 'Likes', value: formatCount((stats['likes'] as num?)?.toInt() ?? 0), color: AppColors.live),
          _Stat(icon: Icons.card_giftcard, label: 'Gifts', value: formatCount((stats['gifts'] as num?)?.toInt() ?? 0), color: AppColors.primary),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
  }
}
