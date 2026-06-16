import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/api/wplus_api.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/wallet.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    final pendingBalance = walletAsync.maybeWhen(
      data: (w) => w.pendingBalance,
      orElse: () => MockData.wallet.pendingBalance,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w800)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: const Color(0xFF1E1E30)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  _BalanceCard(
                    balance: balance,
                    pendingBalance: pendingBalance,
                    onTopUp: () => _topUp(context, ref),
                    onBuy: () => context.push(AppRoutes.giftShop),
                  ),
                  const SizedBox(height: 20),
                  _QuickStats(balance: balance),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  transactionsAsync.maybeWhen(
                    data: (txs) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${txs.length} total',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          transactionsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (transactions) => transactions.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text('💸', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('No transactions yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _TransactionTile(transaction: transactions[i]),
                        childCount: transactions.length,
                      ),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _topUp(BuildContext context, WidgetRef ref) async {
    if (AppConfig.useBackend) {
      try {
        final api = ref.read(wplusApiProvider);
        final newBalance = await api.topUp(500);
        ref.read(walletBalanceProvider.notifier).setBalance(newBalance);
        ref.invalidate(transactionsProvider);
        ref.invalidate(walletProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Top-up failed: $e'), backgroundColor: AppColors.error),
          );
          return;
        }
      }
    } else {
      ref.read(walletBalanceProvider.notifier).adjust(500);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added 500 W to your wallet'), backgroundColor: AppColors.success),
      );
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.pendingBalance,
    required this.onTopUp,
    required this.onBuy,
  });

  final double balance;
  final double pendingBalance;
  final VoidCallback onTopUp;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0060), Color(0xFF0A0020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('W Coins Balance', style: TextStyle(color: Colors.white60, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Active', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
            child: Text(
              '${balance.toStringAsFixed(0)} W',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          if (pendingBalance > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Pending: ${pendingBalance.toInt()} W',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTopUp,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Quick +500', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Buy Packages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('💰', 'Balance', '${balance.toInt()} W'),
      ('📈', 'This Month', '+0 W'),
      ('🎁', 'Gifts Sent', '0'),
    ];

    return Row(
      children: items.map((item) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E1E30)),
          ),
          child: Column(
            children: [
              Text(item.$1, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(item.$3, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text(item.$2, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount > 0;
    final formatter = DateFormat('MMM d, HH:mm');

    IconData icon;
    Color color;
    switch (transaction.type) {
      case TransactionType.gift:
        icon = Icons.card_giftcard_rounded;
        color = AppColors.primary;
      case TransactionType.donation:
        icon = Icons.volunteer_activism_rounded;
        color = AppColors.accent;
      case TransactionType.topup:
        icon = Icons.add_circle_rounded;
        color = AppColors.success;
      default:
        icon = Icons.receipt_rounded;
        color = AppColors.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E30)),
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
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? transaction.type.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${transaction.counterpartyName != null ? '${transaction.counterpartyName} • ' : ''}${formatter.format(transaction.createdAt)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${transaction.amount.toInt()} W',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: isPositive ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
