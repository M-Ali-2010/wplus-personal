import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/wplus_api.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

const _categories = ['Design', 'Tech', 'Music', 'Video', 'Marketing', 'Writing'];

class CreateJobScreen extends ConsumerStatefulWidget {
  const CreateJobScreen({super.key});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tagsController = TextEditingController();
  String _category = _categories.first;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final budgetStr = _budgetController.text.trim();

    if (title.isEmpty || desc.isEmpty || budgetStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all required fields'), backgroundColor: AppColors.error),
      );
      return;
    }

    final budget = double.tryParse(budgetStr);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid budget'), backgroundColor: AppColors.error),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _loading = true);
    try {
      if (AppConfig.useBackend) {
        final api = ref.read(wplusApiProvider);
        await api.createJob(
          title: title,
          description: desc,
          category: _category,
          budget: budget,
          tags: tags.isEmpty ? null : tags,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.gradientCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.work_outline, color: AppColors.primary, size: 36),
                const SizedBox(height: 8),
                const Text('Create a Job Listing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Text('Find talented creators for your project', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Job Title *', prefixIcon: Icon(Icons.title)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description *', alignLabelWithHint: true, prefixIcon: Padding(padding: EdgeInsets.only(bottom: 56), child: Icon(Icons.description_outlined))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Budget (W coins) *', prefixIcon: Icon(Icons.attach_money)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma separated)',
              hintText: 'design, art, animation',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: _loading ? 'POSTING...' : 'POST JOB',
            icon: Icons.publish,
            expanded: true,
            onPressed: _loading ? null : _post,
          ),
        ],
      ),
    );
  }
}
