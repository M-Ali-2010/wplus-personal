import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(leaderboardProvider);

    return entriesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (entries) {
        final sorted = [...entries]..sort((a, b) => a.rank.compareTo(b.rank));

        return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _Tab(label: 'Daily', active: false),
                _Tab(label: 'Weekly', active: true),
                _Tab(label: 'All Time', active: false),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final entry = sorted[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: entry.isCurrentUser ? AppColors.gradientPrimary : null,
                    color: entry.isCurrentUser ? null : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: entry.isCurrentUser ? Colors.transparent : AppColors.surfaceLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: entry.rank <= 3 ? AppColors.warning : null,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: entry.isCurrentUser ? Colors.white24 : AppColors.surfaceLight,
                        child: Text(entry.user.displayName[0]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.user.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: entry.isCurrentUser ? Colors.white : null,
                              ),
                            ),
                            if (entry.isCurrentUser)
                              const Text('You', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Text(
                        '${formatCount(entry.trophies)} 🏆',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: entry.isCurrentUser ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppColors.gradientPrimary : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
