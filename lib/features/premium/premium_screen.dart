import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/wplus_api.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key, this.creatorId});

  final String? creatorId;

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppConfig.useBackend) {
      setState(() {
        _loading = false;
        _posts = [
          {'id': '1', 'title': 'Behind the Scenes', 'price': 50, 'isLocked': true, 'isPremium': true},
          {'id': '2', 'title': 'Exclusive Tutorial', 'price': 0, 'isLocked': false, 'isPremium': false, 'content': 'Free content preview'},
        ];
      });
      return;
    }
    try {
      final api = ref.read(wplusApiProvider);
      _posts = await api.fetchPremiumPosts(creatorId: widget.creatorId);
      if (widget.creatorId != null) {
        _isSubscribed = await api.checkSubscription(widget.creatorId!);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _subscribe() async {
    if (widget.creatorId == null) return;
    try {
      final api = ref.read(wplusApiProvider);
      await api.subscribe(widget.creatorId!);
      await ref.read(walletBalanceProvider.notifier).refresh();
      setState(() => _isSubscribed = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscribed! Premium content unlocked.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscribe failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _purchase(String postId) async {
    try {
      final api = ref.read(wplusApiProvider);
      final post = await api.purchasePremiumPost(postId);
      await ref.read(walletBalanceProvider.notifier).refresh();
      setState(() {
        final idx = _posts.indexWhere((p) => p['id'] == postId);
        if (idx >= 0) _posts[idx] = post;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Content')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.creatorId != null && !_isSubscribed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Premium Subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                        const Text('99 W/month — unlock all premium posts', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        GradientButton(label: 'SUBSCRIBE', icon: Icons.star, onPressed: _subscribe),
                      ],
                    ),
                  ),
                if (_posts.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No premium content yet', style: TextStyle(color: AppColors.textMuted)))),
                ..._posts.map((post) {
                  final locked = post['isLocked'] as bool? ?? false;
                  final price = (post['price'] as num?)?.toDouble() ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(locked ? Icons.lock : Icons.lock_open, color: AppColors.primary),
                      title: Text(post['title'] as String? ?? ''),
                      subtitle: locked
                          ? Text('${price.toInt()} W to unlock')
                          : Text(post['content'] as String? ?? 'Unlocked'),
                      trailing: locked && price > 0
                          ? TextButton(onPressed: () => _purchase(post['id'] as String), child: const Text('Buy'))
                          : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
