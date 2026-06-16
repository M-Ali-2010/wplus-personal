import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/wplus_api.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

final _jobCategoryProvider = StateProvider<String?>((ref) => null);

final _jobsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, category) async {
  if (!AppConfig.useBackend) return _mockJobs;
  final api = ref.watch(wplusApiProvider);
  await api.ensureLoggedIn();
  return api.fetchJobs(category: category);
});

const _mockJobs = [
  {
    'id': 'j1',
    'title': 'Stream Thumbnail Designer',
    'description': 'Need eye-catching thumbnails for weekly live streams. Consistent style, fast delivery.',
    'category': 'Design',
    'budget': 150.0,
    'currency': 'W',
    'tags': ['design', 'thumbnail', 'art'],
    'applicantsCount': 8,
    'poster': {'displayName': 'NikoLive', 'isVerified': true},
    'createdAt': '2026-06-15T10:00:00Z',
  },
  {
    'id': 'j2',
    'title': 'AI Chat Bot Moderator',
    'description': 'Set up and maintain AI bots for live stream chat. Must know prompt engineering.',
    'category': 'Tech',
    'budget': 300.0,
    'currency': 'W',
    'tags': ['ai', 'bot', 'moderation'],
    'applicantsCount': 12,
    'poster': {'displayName': 'TechStream', 'isVerified': false},
    'createdAt': '2026-06-14T08:30:00Z',
  },
  {
    'id': 'j3',
    'title': 'Music Composer for Battle Streams',
    'description': 'Compose short 60-second battle tracks. Energetic, EDM/trap style.',
    'category': 'Music',
    'budget': 200.0,
    'currency': 'W',
    'tags': ['music', 'edm', 'battle'],
    'applicantsCount': 5,
    'poster': {'displayName': 'BeatMaker9', 'isVerified': true},
    'createdAt': '2026-06-13T15:00:00Z',
  },
  {
    'id': 'j4',
    'title': 'Video Editor — Stream Highlights',
    'description': 'Cut live stream VODs into 60-second highlight reels for social media.',
    'category': 'Video',
    'budget': 250.0,
    'currency': 'W',
    'tags': ['video', 'editing', 'highlights'],
    'applicantsCount': 19,
    'poster': {'displayName': 'LunaArt', 'isVerified': true},
    'createdAt': '2026-06-12T12:00:00Z',
  },
  {
    'id': 'j5',
    'title': 'Social Media Manager',
    'description': 'Manage TikTok, Instagram, Twitter for growing creator. 10h/week.',
    'category': 'Marketing',
    'budget': 500.0,
    'currency': 'W',
    'tags': ['social', 'marketing', 'content'],
    'applicantsCount': 23,
    'poster': {'displayName': 'MegaCreator', 'isVerified': false},
    'createdAt': '2026-06-11T09:00:00Z',
  },
];

const _categories = ['Design', 'Tech', 'Music', 'Video', 'Marketing', 'Writing'];
const _categoryIcons = {
  'Design': Icons.palette_outlined,
  'Tech': Icons.code_outlined,
  'Music': Icons.music_note_outlined,
  'Video': Icons.videocam_outlined,
  'Marketing': Icons.trending_up_outlined,
  'Writing': Icons.edit_outlined,
};

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(_jobCategoryProvider);
    final jobsAsync = ref.watch(_jobsProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Post a Job',
            onPressed: () => context.push('/marketplace/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryFilter(selected: category, onSelect: (c) {
            ref.read(_jobCategoryProvider.notifier).state = c;
          }),
          Expanded(
            child: jobsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (jobs) => jobs.isEmpty
                  ? const Center(
                      child: Text('No jobs yet', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: jobs.length,
                      itemBuilder: (context, i) => _JobCard(
                        job: jobs[i],
                        onTap: () => context.push('/marketplace/jobs/${jobs[i]['id']}', extra: jobs[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onSelect});
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(label: 'All', selected: selected == null, onTap: () => onSelect(null)),
          ..._categories.map((c) => _Chip(
                label: c,
                selected: selected == c,
                onTap: () => onSelect(selected == c ? null : c),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradientPrimary : null,
            color: selected ? null : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final poster = job['poster'] as Map<String, dynamic>? ?? {};
    final budget = (job['budget'] as num?)?.toDouble() ?? 0;
    final applicants = (job['applicantsCount'] as num?)?.toInt() ?? 0;
    final category = job['category'] as String? ?? '';
    final tags = (job['tags'] as List?)?.cast<String>() ?? [];
    final icon = _categoryIcons[category] ?? Icons.work_outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            poster['displayName'] as String? ?? '',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          if (poster['isVerified'] == true) ...[
                            const SizedBox(width: 2),
                            const VerifiedBadge(size: 12),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${budget.toInt()} W',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              job['description'] as String? ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#$tag', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.people_outline, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('$applicants applicants', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
