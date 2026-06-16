import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/wplus_api.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final balance = ref.watch(walletBalanceProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _ProfileHeader(user: user, balance: balance),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StatsRow(user: user),
                  const SizedBox(height: 20),
                  if (user.bio != null) ...[
                    Text(
                      user.bio!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (user.isCreator) ...[
                    _CreatorActions(user: user),
                    const SizedBox(height: 20),
                  ],
                  _WalletCard(balance: balance),
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _MenuGrid(user: user, ref: ref),
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Account'),
                  const SizedBox(height: 12),
                  _AccountActions(user: user, ref: ref),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.balance});

  final dynamic user;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0533), Color(0xFF050510)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  _GradientAvatar(name: user.displayName, radius: 50),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 6),
                        const VerifiedBadge(size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  if (user.isCreator) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CREATOR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2 + 6,
      height: radius * 2 + 6,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.surfaceLight,
          child: Text(
            name[0].toUpperCase(),
            style: TextStyle(
              fontSize: radius * 0.7,
              fontWeight: FontWeight.w800,
              foreground: Paint()
                ..shader = AppColors.gradientPrimary.createShader(
                  Rect.fromLTWH(0, 0, radius * 2, radius * 2),
                ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E30)),
      ),
      child: Row(
        children: [
          _StatItem(value: formatCount(user.followersCount), label: 'Followers'),
          _VertDivider(),
          _StatItem(value: formatCount(user.followingCount), label: 'Following'),
          _VertDivider(),
          _StatItem(value: formatCount(user.trophies ?? 0), label: 'Trophies', icon: '🏆'),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFF1E1E30));
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Text(icon!, style: const TextStyle(fontSize: 14)), const SizedBox(width: 4)],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0060), Color(0xFF1A0040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('W Coins Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                  child: Text(
                    '${balance.toStringAsFixed(0)} W',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.wallet),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'View',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CreatorActions extends StatelessWidget {
  const _CreatorActions({required this.user});

  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GradientButton(
            label: 'Dashboard',
            icon: Icons.dashboard_rounded,
            onPressed: () => context.push(AppRoutes.dashboard),
            expanded: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.startLive),
            icon: const Icon(Icons.videocam_rounded, size: 18),
            label: const Text('Go Live'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.user, required this.ref});

  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuTile(
        icon: Icons.flash_on_rounded,
        label: 'AI Battles',
        color: const Color(0xFF7C3AED),
        onTap: () => context.push(AppRoutes.battleSetup),
      ),
      _MenuTile(
        icon: Icons.shopping_bag_rounded,
        label: 'Buy Coins',
        color: AppColors.primary,
        onTap: () => context.push(AppRoutes.giftShop),
      ),
      _MenuTile(
        icon: Icons.mail_rounded,
        label: 'Paid DMs',
        color: const Color(0xFF0EA5E9),
        onTap: () {},
      ),
      _MenuTile(
        icon: Icons.lock_rounded,
        label: 'Premium',
        color: const Color(0xFFEA580C),
        onTap: () => context.push('${AppRoutes.premium}?creatorId=${user.id}'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: items.map((item) => _MenuTileWidget(tile: item)).toList(),
    );
  }
}

class _MenuTile {
  const _MenuTile({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _MenuTileWidget extends StatelessWidget {
  const _MenuTileWidget({required this.tile});

  final _MenuTile tile;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tile.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E30)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tile.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tile.icon, color: tile.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tile.label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActions extends ConsumerWidget {
  const _AccountActions({required this.user, required this.ref});

  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ActionListTile(
          icon: Icons.person_outline_rounded,
          label: 'Edit Profile',
          onTap: () {},
        ),
        _ActionListTile(
          icon: Icons.shield_outlined,
          label: 'Privacy & Safety',
          onTap: () {},
        ),
        _ActionListTile(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () {},
        ),
        _ActionListTile(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          isDestructive: true,
          onTap: () async {
            final api = ref.read(wplusApiProvider);
            await api.logout();
            if (context.mounted) context.go(AppRoutes.login);
          },
        ),
      ],
    );
  }
}

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E30)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
