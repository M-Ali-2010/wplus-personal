import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Creator Dashboard')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (data) {
        final revenue = (data['revenue'] as Map?)?['total'] as num? ?? 0;
        final gifts = data['gifts'] as Map? ?? {};
        final donations = data['donations'] as Map? ?? {};
        final paidMessages = data['paidMessages'] as Map? ?? {};
        final streams = data['streams'] as Map? ?? {};
        final payout = data['availableForPayout'] as num? ?? 0;

        return Scaffold(
          appBar: AppBar(title: const Text('Creator Dashboard')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${revenue.toInt()} W',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Revenue Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _DashboardCard(
                icon: Icons.card_giftcard,
                title: 'Gifts',
                value: '${(gifts['total'] as num? ?? 0).toInt()} W',
                subtitle: '${gifts['count'] ?? 0} gifts received',
                color: AppColors.primary,
              ),
              _DashboardCard(
                icon: Icons.volunteer_activism,
                title: 'Donations',
                value: '${(donations['total'] as num? ?? 0).toInt()} W',
                subtitle: '${donations['count'] ?? 0} supporters',
                color: AppColors.accent,
              ),
              _DashboardCard(
                icon: Icons.mail,
                title: 'Paid Messages',
                value: '${(paidMessages['total'] as num? ?? 0).toInt()} W',
                subtitle: '${paidMessages['count'] ?? 0} messages',
                color: AppColors.secondary,
              ),
              _DashboardCard(
                icon: Icons.live_tv,
                title: 'Live Streams',
                value: '${streams['total'] ?? 0} total',
                subtitle: '${streams['live'] ?? 0} live • ${streams['totalViewers'] ?? 0} peak viewers',
                color: AppColors.live,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available for Payout', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${payout.toInt()} W', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payout request submitted')),
                        );
                      },
                      child: const Text('Request Payout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
