import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/api/wplus_api.dart';
import '../../core/models/stream.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';
import '../donate/donate_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _HomeAppBar(balance: balance),
          SliverToBoxAdapter(
            child: _LiveNowSection(onStreamTap: (id) => context.push('/live/$id')),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          const _PostsFeed(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      elevation: 0,
      title: Row(
        children: [
          const WPlusLogo(size: 30),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Creator Economy',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _NotificationBtn(),
        const SizedBox(width: 4),
        WCoinBadge(amount: balance, compact: true),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.surfaceLight),
      ),
    );
  }
}

class _NotificationBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
          onPressed: () {},
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveNowSection extends ConsumerWidget {
  const _LiveNowSection({required this.onStreamTap});

  final void Function(String id) onStreamTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(liveStreamsProvider);

    return streamsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (streams) {
        if (streams.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.live.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${streams.length}',
                      style: const TextStyle(
                        color: AppColors.live,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.live),
                    child: const Row(
                      children: [
                        Text(
                          'See all',
                          style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: streams.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _LiveStreamCard(
                  stream: streams[index],
                  onTap: () => onStreamTap(streams[index].id),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.live,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.live.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 2)],
        ),
      ),
    );
  }
}

final _gradientPairs = [
  [const Color(0xFF6B21A8), const Color(0xFFFF00FF)],
  [const Color(0xFF0F172A), const Color(0xFF8A2BE2)],
  [const Color(0xFF1A0533), const Color(0xFFFF1493)],
  [const Color(0xFF0D1B2A), const Color(0xFF00B4D8)],
  [const Color(0xFF1B1B2F), const Color(0xFF8338EC)],
];

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream, required this.onTap});

  final LiveStream stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _gradientPairs[stream.id.hashCode.abs() % _gradientPairs.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[1].withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // avatar letter
              Center(
                child: Text(
                  stream.creator.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white24,
                  ),
                ),
              ),
              // bottom gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // LIVE badge
              Positioned(
                top: 10,
                left: 10,
                child: LiveBadge(viewerCount: stream.viewerCount),
              ),
              // creator info
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.creator.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stream.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostsFeed extends ConsumerWidget {
  const _PostsFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return postsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        )),
      ),
      error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
      data: (posts) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _PostCard(
            post: posts[i],
            onSupport: () => showDonateSheet(
              context,
              creatorName: posts[i].creator.displayName,
              onDonate: (amount) async {
                if (AppConfig.useBackend) {
                  try {
                    final api = ref.read(wplusApiProvider);
                    await api.sendDonation(
                      receiverId: posts[i].creator.id,
                      amount: amount,
                      postId: posts[i].id,
                    );
                    await ref.read(walletBalanceProvider.notifier).refresh();
                    ref.invalidate(transactionsProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Donation failed: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                } else {
                  ref.read(walletBalanceProvider.notifier).adjustOptimistic(-amount);
                }
              },
            ),
          ),
          childCount: posts.length,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onSupport});

  final dynamic post;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E30), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                _CreatorAvatar(name: post.creator.displayName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.creator.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          if (post.creator.isVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(size: 14),
                          ],
                        ],
                      ),
                      Text(
                        '@${post.creator.username}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (post.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Premium',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          if (post.isPremium)
            _PremiumLockBanner()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 12),
          // Divider
          const Divider(color: Color(0xFF1E1E30), height: 1),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.favorite_border_rounded,
                  label: formatCount(post.likesCount),
                  onTap: () {},
                ),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                  onTap: () {},
                ),
                const Spacer(),
                _SupportButton(onPressed: onSupport, donationsCount: post.donationsCount),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = _gradientPairs[name.hashCode.abs() % _gradientPairs.length];
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: colors[1].withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 0)],
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}

class _PremiumLockBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, color: AppColors.primary, size: 28),
            SizedBox(height: 6),
            Text(
              'Premium Content',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              'Subscribe to unlock',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.textMuted),
      label: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({required this.onPressed, required this.donationsCount});

  final VoidCallback onPressed;
  final int donationsCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              donationsCount > 0 ? 'Support · $donationsCount' : 'Support',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
