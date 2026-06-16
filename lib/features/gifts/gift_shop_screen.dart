import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/api/wplus_api.dart';
import '../../core/data/mock_data.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class GiftShopScreen extends ConsumerWidget {
  const GiftShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final owned = ref.watch(ownedGiftsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buy W Coins')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Balance', style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 4),
                      Text('Use W coins for gifts & battles', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                WCoinBadge(amount: balance),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Top Up Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Purchase W coins to send AI-generated animated gifts in streams and battles.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...MockData.giftPackages.map((pkg) {
            final total = pkg.amount + pkg.bonus;
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.monetization_on, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${total.toInt()} W', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        if (pkg.bonus > 0)
                          Text('+${pkg.bonus.toInt()} bonus', style: const TextStyle(color: AppColors.success, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (AppConfig.useBackend) {
                        try {
                          final api = ref.read(wplusApiProvider);
                          final newBalance = await api.topUp(total);
                          ref.read(walletBalanceProvider.notifier).setBalance(newBalance);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Top-up failed: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      } else {
                        ref.read(walletBalanceProvider.notifier).adjustOptimistic(total);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${total.toInt()} W to your balance'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: Text('\$${pkg.priceUsd.toStringAsFixed(2)}'),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text('Your Gift Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (owned.isEmpty)
            const Text('No gifts yet — buy W coins and send gifts in live streams', style: TextStyle(color: AppColors.textMuted))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: owned.entries.map((entry) {
                final gift = MockData.gifts.firstWhere((g) => g.id == entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(gift.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('${gift.title} x${entry.value}'),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All gifts are AI-generated animations (GIF/Lottie/MP4) — integrated via backend asset storage.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
