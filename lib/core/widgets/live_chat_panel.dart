import 'package:flutter/material.dart';

import '../models/stream.dart';
import '../theme/app_colors.dart';

class LiveChatPanel extends StatefulWidget {
  const LiveChatPanel({
    super.key,
    required this.comments,
    this.maxHeight = 160,
    this.showAiBadge = true,
    this.onLongPressUser,
  });

  final List<StreamComment> comments;
  final double maxHeight;
  final bool showAiBadge;
  final void Function(String userId, String displayName)? onLongPressUser;

  @override
  State<LiveChatPanel> createState() => _LiveChatPanelState();
}

class _LiveChatPanelState extends State<LiveChatPanel> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(LiveChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comments.length > oldWidget.comments.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.comments.length,
        itemBuilder: (context, index) {
          final comment = widget.comments[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: GestureDetector(
              onLongPress: () {
                if (widget.onLongPressUser != null && !comment.isAi) {
                  widget.onLongPressUser!(comment.user.id, comment.user.displayName);
                }
              },
              child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: comment.isAi
                        ? AppColors.secondary.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.3),
                    child: Text(
                      comment.user.displayName[0],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                        children: [
                          TextSpan(
                            text: '${comment.user.displayName} ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: comment.isPaid
                                  ? AppColors.secondary
                                  : comment.isAi
                                      ? AppColors.secondary
                                      : AppColors.primary,
                            ),
                          ),
                          TextSpan(text: comment.text),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showAiBadge && comment.isAi)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('AI', style: TextStyle(fontSize: 8, color: AppColors.secondary)),
                    ),
                  if (comment.isPaid)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('💎', style: TextStyle(fontSize: 8)),
                    ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}
