import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/gift.dart';
import '../theme/app_colors.dart';

/// Renders gift animation — Lottie/GIF when assetUrl available, emoji fallback.
class GiftAnimationWidget extends StatelessWidget {
  const GiftAnimationWidget({
    super.key,
    required this.gift,
    this.size = 80,
    this.opacity = 1.0,
    this.scale = 1.0,
  });

  final Gift gift;
  final double size;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    Widget child;

    final url = gift.assetUrl;
    if (url != null && gift.assetType == GiftAssetType.lottie) {
      child = Lottie.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, e, s) => _emojiView(),
      );
    } else if (url != null && gift.assetType == GiftAssetType.gif) {
      child = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (_, e, s) => _emojiView(),
      );
    } else {
      child = _emojiView();
    }

    return Opacity(
      opacity: opacity,
      child: Transform.scale(scale: scale, child: child),
    );
  }

  Widget _emojiView() {
    final isLottie = gift.assetType == GiftAssetType.lottie;
    final isLuxury = gift.assetType == GiftAssetType.mp4 || gift.price >= 100;

    return Container(
      width: size,
      height: size,
      decoration: isLuxury
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 4),
              ],
            )
          : null,
      child: Center(
        child: Text(
          gift.emoji,
          style: TextStyle(
            fontSize: size * 0.7,
            shadows: isLottie
                ? [Shadow(color: AppColors.secondary.withValues(alpha: 0.8), blurRadius: 12)]
                : null,
          ),
        ),
      ),
    );
  }
}
