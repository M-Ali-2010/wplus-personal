import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/gift.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class GiftCatalogScreen extends ConsumerWidget {
  const GiftCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(giftsProvider);
    final selectedCategory = ref.watch(selectedGiftCategoryProvider);

    return giftsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (gifts) {
        final categories = GiftCategory.values;
        final filtered = selectedCategory == null
            ? gifts
            : gifts.where((g) => g.category == selectedCategory).toList();

        return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Gifts'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.giftShop),
            child: const Text('Buy W'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.gradientPrimary.createShader(bounds),
                    child: const Text(
                      'More than gifts. Emotions in motion.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stunning animated GIF gifts that make every interaction special.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: selectedCategory == null,
                    onTap: () => ref.read(selectedGiftCategoryProvider.notifier).state = null,
                  ),
                  ...categories.map((cat) => _CategoryChip(
                        label: _categoryName(cat),
                        selected: selectedCategory == cat,
                        onTap: () => ref.read(selectedGiftCategoryProvider.notifier).state = cat,
                      )),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _GiftCard(gift: filtered[index]),
                childCount: filtered.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _HowGiftsWork()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
      },
    );
  }

  String _categoryName(GiftCategory cat) {
    switch (cat) {
      case GiftCategory.popular:
        return 'Popular';
      case GiftCategory.luxury:
        return 'Luxury';
      case GiftCategory.exclusive:
        return 'Exclusive';
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradientPrimary : null,
            color: selected ? null : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({required this.gift});

  final Gift gift;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(gift.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            gift.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          WCoinBadge(amount: gift.price, compact: true),
        ],
      ),
    );
  }
}

class _HowGiftsWork extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Choose a Gift', 'Pick your favorite animated gift', Icons.card_giftcard),
      ('Send in Chat', 'Your gift appears instantly', Icons.chat),
      ('Amazing Effect', 'Cool animation on stream', Icons.auto_awesome),
      ('Support Creator', 'Creator earns W coins', Icons.monetization_on),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How Gifts Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step.$3, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(step.$2, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
