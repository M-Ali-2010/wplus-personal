import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/stream.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

final _gradientPairs = [
  [const Color(0xFF6B21A8), const Color(0xFFFF00FF)],
  [const Color(0xFF0F172A), const Color(0xFF8A2BE2)],
  [const Color(0xFF1A0533), const Color(0xFFFF1493)],
  [const Color(0xFF0D1B2A), const Color(0xFF00B4D8)],
  [const Color(0xFF1B1B2F), const Color(0xFF8338EC)],
];

class LiveFeedScreen extends ConsumerStatefulWidget {
  const LiveFeedScreen({super.key});

  @override
  ConsumerState<LiveFeedScreen> createState() => _LiveFeedScreenState();
}

class _LiveFeedScreenState extends ConsumerState<LiveFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamsAsync = ref.watch(liveStreamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Row(
              children: [
                const Text('Live', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
                const SizedBox(width: 10),
                streamsAsync.when(
                  data: (s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.live.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${s.length} live',
                      style: const TextStyle(color: AppColors.live, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            actions: [
              _GoLiveBtn(onTap: () => context.push(AppRoutes.startLive)),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E1E30))),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Streams'),
                    Tab(text: 'AI Battles'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            streamsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (streams) => _StreamsGrid(streams: streams),
            ),
            const _BattlesTab(),
          ],
        ),
      ),
    );
  }
}

class _GoLiveBtn extends StatelessWidget {
  const _GoLiveBtn({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text('Go Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _StreamsGrid extends StatelessWidget {
  const _StreamsGrid({required this.streams});

  final List<LiveStream> streams;

  @override
  Widget build(BuildContext context) {
    if (streams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📡', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('No live streams right now', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            SizedBox(height: 8),
            Text('Be the first to go live!', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: streams.length,
      itemBuilder: (context, index) => _StreamCard(
        stream: streams[index],
        onTap: () => context.push('/live/${streams[index].id}'),
      ),
    );
  }
}

class _StreamCard extends StatelessWidget {
  const _StreamCard({required this.stream, required this.onTap});

  final LiveStream stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _gradientPairs[stream.id.hashCode.abs() % _gradientPairs.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[1].withValues(alpha: 0.25),
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
              Center(
                child: Text(
                  stream.creator.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white12,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(top: 10, left: 10, child: LiveBadge(viewerCount: stream.viewerCount)),
              if (stream.giftsTotal > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎁', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          stream.giftsTotal.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stream.creator.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (stream.creator.isVerified) ...[
                          const SizedBox(width: 3),
                          const VerifiedBadge(size: 12),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stream.title,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      maxLines: 2,
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

class _BattlesTab extends ConsumerWidget {
  const _BattlesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opponentsAsync = ref.watch(aiOpponentsProvider);
    final rewards = ref.watch(battleRewardsProvider);

    return opponentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (opponents) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          _BattlesHero(),
          const SizedBox(height: 20),
          GradientButton(
            label: 'START AI BATTLE',
            icon: Icons.flash_on_rounded,
            expanded: true,
            onPressed: () => context.push(AppRoutes.battleSetup),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.leaderboard),
            icon: const Icon(Icons.leaderboard_rounded, size: 18),
            label: const Text('Leaderboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 28),
          const Text('Choose Opponent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...opponents.map((op) => _OpponentCard(opponent: op)),
          const SizedBox(height: 28),
          const Text('Battle Rewards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: rewards.map((r) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E1E30)),
                ),
                child: Column(
                  children: [
                    Text(r.icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(r.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    if (r.trophies > 0)
                      Text('+${r.trophies}🏆', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _BattlesHero extends StatelessWidget {
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
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                  child: const Text(
                    'AI Battles',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Compete live. Win trophies.\nEarn W Coins.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const Text('⚔️', style: TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({required this.opponent});

  final dynamic opponent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E30)),
      ),
      child: Row(
        children: [
          Text(opponent.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opponent.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(opponent.tagline, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${opponent.winRate}% win',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
