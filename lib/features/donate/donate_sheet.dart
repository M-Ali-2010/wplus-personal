import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class DonateSheet extends StatefulWidget {
  const DonateSheet({
    super.key,
    required this.creatorName,
    required this.onDonate,
  });

  final String creatorName;
  final void Function(double amount) onDonate;

  @override
  State<DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends State<DonateSheet> {
  double? _selectedAmount;
  final _customController = TextEditingController();
  final _commentController = TextEditingController();

  static const _quickAmounts = [1.0, 5.0, 10.0, 25.0];

  @override
  void dispose() {
    _customController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double? get _amount {
    if (_selectedAmount != null) return _selectedAmount;
    final custom = double.tryParse(_customController.text);
    return custom != null && custom > 0 ? custom : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Support ${widget.creatorName}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Donate instead of like — show real support',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickAmounts.map((amount) {
              final selected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedAmount = amount;
                  _customController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.gradientPrimary : null,
                    color: selected ? null : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.surfaceLight,
                    ),
                  ),
                  child: Text(
                    '${amount.toInt()} W',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _selectedAmount = null),
            decoration: const InputDecoration(
              hintText: 'Custom amount (W)',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Add a message (optional)',
              prefixIcon: Icon(Icons.chat_bubble_outline),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _amount == null
                  ? null
                  : () {
                      widget.onDonate(_amount!);
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sent ${_amount!.toInt()} W to ${widget.creatorName}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
              child: Text(_amount == null ? 'Select amount' : 'Send ${_amount!.toInt()} W'),
            ),
          ),
        ],
      ),
    );
  }
}

void showDonateSheet(
  BuildContext context, {
  required String creatorName,
  required void Function(double amount) onDonate,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => DonateSheet(creatorName: creatorName, onDonate: onDonate),
  );
}
