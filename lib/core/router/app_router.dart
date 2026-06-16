import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../api/api_client.dart';
import '../theme/app_colors.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/battle/battle_room_screen.dart';
import '../../features/battle/battle_setup_screen.dart';
import '../../features/battle/leaderboard_screen.dart';
import '../../features/dashboard/creator_dashboard_screen.dart';
import '../../features/gifts/gift_catalog_screen.dart';
import '../../features/gifts/gift_shop_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/live/live_feed_screen.dart';
import '../../features/live/live_room_screen.dart';
import '../../features/live/start_live_screen.dart';
import '../../features/marketplace/create_job_screen.dart';
import '../../features/marketplace/job_detail_screen.dart';
import '../../features/marketplace/marketplace_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/wallet/wallet_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const live = '/live';
  static const liveRoom = '/live/:id';
  static const startLive = '/start-live';
  static const battleSetup = '/battle/setup';
  static const battleRoom = '/battle/room';
  static const leaderboard = '/leaderboard';
  static const gifts = '/gifts';
  static const giftShop = '/gift-shop';
  static const profile = '/profile';
  static const dashboard = '/dashboard';
  static const wallet = '/wallet';
  static const premium = '/premium';
  static const marketplace = '/marketplace';
  static const marketplaceCreate = '/marketplace/create';
  static const marketplaceJob = '/marketplace/jobs/:id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authToken = ref.watch(authTokenProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      if (!AppConfig.useBackend) return null;

      final isAuth = authToken != null;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register;

      if (!isAuth && !isAuthRoute) return AppRoutes.login;
      if (isAuth && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.live,
            pageBuilder: (context, state) => const NoTransitionPage(child: LiveFeedScreen()),
          ),
          GoRoute(
            path: AppRoutes.gifts,
            pageBuilder: (context, state) => const NoTransitionPage(child: GiftCatalogScreen()),
          ),
          GoRoute(
            path: AppRoutes.marketplace,
            pageBuilder: (context, state) => const NoTransitionPage(child: MarketplaceScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.liveRoom,
        builder: (context, state) => LiveRoomScreen(
          streamId: state.pathParameters['id']!,
          publisherLivekit: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: AppRoutes.startLive,
        builder: (context, state) => const StartLiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.battleSetup,
        builder: (context, state) => const BattleSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.battleRoom,
        builder: (context, state) => const BattleRoomScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.giftShop,
        builder: (context, state) => const GiftShopScreen(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => PremiumScreen(creatorId: state.uri.queryParameters['creatorId']),
      ),
      GoRoute(
        path: AppRoutes.marketplaceCreate,
        builder: (context, state) => const CreateJobScreen(),
      ),
      GoRoute(
        path: AppRoutes.marketplaceJob,
        builder: (context, state) => JobDetailScreen(
          jobId: state.pathParameters['id']!,
          jobData: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _locationToIndex(String location) {
    if (location.startsWith('/live')) return 1;
    if (location.startsWith('/gifts')) return 2;
    if (location.startsWith('/marketplace')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.live);
      case 2:
        context.go(AppRoutes.gifts);
      case 3:
        context.go(AppRoutes.marketplace);
      case 4:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: currentIndex,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv_rounded, label: 'Live'),
      _NavItem(icon: Icons.card_giftcard_outlined, activeIcon: Icons.card_giftcard, label: 'Gifts'),
      _NavItem(icon: Icons.work_outline_rounded, activeIcon: Icons.work_rounded, label: 'Jobs'),
      _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.85),
            border: const Border(
              top: BorderSide(color: Color(0xFF2A2A40), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final active = i == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: active
                                  ? ShaderMask(
                                      key: const ValueKey('active'),
                                      shaderCallback: (b) =>
                                          AppColors.gradientPrimary.createShader(b),
                                      child: Icon(item.activeIcon, color: Colors.white, size: 26),
                                    )
                                  : Icon(
                                      item.icon,
                                      key: const ValueKey('inactive'),
                                      color: AppColors.textMuted,
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                color: active ? AppColors.primary : AppColors.textMuted,
                              ),
                              child: Text(item.label),
                            ),
                            if (active)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 3),
                                decoration: const BoxDecoration(
                                  gradient: AppColors.gradientPrimary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 7),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
