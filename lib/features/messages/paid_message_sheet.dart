import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/wplus_api.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

const paidMessagePrice = 5.0;

void showPaidMessageSheet(
  BuildContext context, {
  required String receiverId,
  required String creatorName,
  String? streamId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PaidMessageSheet(
      receiverId: receiverId,
      creatorName: creatorName,
      streamId: streamId,
    ),
  );
}

class PaidMessageSheet extends ConsumerStatefulWidget {
  const PaidMessageSheet({
    super.key,
    required this.receiverId,
    required this.creatorName,
    this.streamId,
  });

  final String receiverId;
  final String creatorName;
  final String? streamId;

  @override
  ConsumerState<PaidMessageSheet> createState() => _PaidMessageSheetState();
}

class _PaidMessageSheetState extends ConsumerState<PaidMessageSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final balance = ref.read(walletBalanceProvider);
    if (balance < paidMessagePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _sending = true);
    VoidCallback? rollback;

    if (!AppConfig.useBackend) {
      rollback = ref.read(walletBalanceProvider.notifier).adjustOptimistic(-paidMessagePrice);
    }

    try {
      if (AppConfig.useBackend) {
        final api = ref.read(wplusApiProvider);
        await api.sendPaidMessage(
          receiverId: widget.receiverId,
          text: text,
          amount: paidMessagePrice,
          streamId: widget.streamId,
        );
        await ref.read(walletBalanceProvider.notifier).refresh();
      }

      if (widget.streamId != null) {
        ref.read(liveChatProvider(widget.streamId).notifier).addUserComment(
              '💎 $text',
              displayName: 'You',
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paid message sent (${paidMessagePrice.toInt()} W)'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      rollback?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(walletBalanceProvider);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Paid Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                WCoinBadge(amount: balance, compact: true),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Highlight your message in ${widget.creatorName}\'s chat for ${paidMessagePrice.toInt()} W',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Your highlighted message...',
                prefixIcon: Icon(Icons.diamond_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: _sending ? 'SENDING...' : 'SEND FOR ${paidMessagePrice.toInt()} W',
              icon: Icons.send,
              expanded: true,
              onPressed: _sending ? () {} : _send,
            ),
          ],
        ),
      ),
    );
  }
}
