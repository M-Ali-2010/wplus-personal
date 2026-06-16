import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/wplus_api.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId, this.jobData});

  final String jobId;
  final Map<String, dynamic>? jobData;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Map<String, dynamic>? _job;
  bool _loading = true;
  bool _applying = false;
  bool _applied = false;
  final _coverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.jobData != null) {
      _job = widget.jobData;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (!AppConfig.useBackend) {
      setState(() => _loading = false);
      return;
    }
    try {
      final api = ref.read(wplusApiProvider);
      _job = await api.fetchJob(widget.jobId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      if (AppConfig.useBackend) {
        final api = ref.read(wplusApiProvider);
        await api.applyJob(widget.jobId, coverLetter: _coverController.text.trim().isEmpty ? null : _coverController.text.trim());
      }
      if (mounted) {
        setState(() => _applied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applied successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  void dispose() {
    _coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final job = _job;
    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job')),
        body: const Center(child: Text('Job not found')),
      );
    }

    final poster = job['poster'] as Map<String, dynamic>? ?? {};
    final budget = (job['budget'] as num?)?.toDouble() ?? 0;
    final applicants = (job['applicantsCount'] as num?)?.toInt() ?? 0;
    final tags = (job['tags'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(job['category'] as String? ?? 'Job'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradientCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['title'] as String? ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (poster['displayName'] as String? ?? 'U')[0],
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(poster['displayName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (poster['isVerified'] == true) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(icon: Icons.attach_money, label: '${budget.toInt()} W'),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.people_outline, label: '$applicants applied'),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.category_outlined, label: job['category'] as String? ?? ''),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(job['description'] as String? ?? '', style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text('#$tag', style: const TextStyle(color: AppColors.primary, fontSize: 13)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 24),
          if (!_applied) ...[
            const Text('Cover Letter (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _coverController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell the poster why you\'re the best fit...',
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: _applying ? 'Applying...' : 'Apply Now',
              icon: Icons.send,
              expanded: true,
              onPressed: _applying ? null : _apply,
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 12),
                  Text('Application submitted!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
