import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/app_config.dart';
import '../../core/api/wplus_api.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/wplus_widgets.dart';

class StartLiveScreen extends ConsumerStatefulWidget {
  const StartLiveScreen({super.key});

  @override
  ConsumerState<StartLiveScreen> createState() => _StartLiveScreenState();
}

class _StartLiveScreenState extends ConsumerState<StartLiveScreen> {
  final _titleController = TextEditingController(text: 'My Live Stream');
  String _category = 'Music';
  bool _allowGifts = true;
  bool _allowDonations = true;
  bool _enableAi = true;
  bool _enableAiBots = true;
  bool _loading = false;
  bool _permissionsGranted = false;
  CameraController? _previewCamera;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final granted = statuses[Permission.camera]?.isGranted == true &&
        statuses[Permission.microphone]?.isGranted == true;
    if (granted) {
      await _initPreview();
    }
    if (mounted) setState(() => _permissionsGranted = granted);
  }

  Future<void> _initPreview() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(front, ResolutionPreset.medium);
      await controller.initialize();
      if (mounted) setState(() => _previewCamera = controller);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _previewCamera?.dispose();
    super.dispose();
  }

  Future<void> _goLive() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      if (!_permissionsGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and microphone permissions required'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    setState(() => _loading = true);
    try {
      if (AppConfig.useBackend) {
        final api = ref.read(wplusApiProvider);
        final stream = await api.createStream(
          title: _titleController.text.trim(),
          category: _category,
          aiEnabled: _enableAi,
        );
        final started = await api.startStream(stream['id'] as String);
        final streamId = started['stream']?['id'] as String? ?? stream['id'] as String;
        final livekit = started['livekit'] as Map<String, dynamic>?;
        if (mounted) context.pushReplacement('/live/$streamId', extra: livekit);
      } else {
        if (mounted) context.pushReplacement('/live/new');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start stream: $e'), backgroundColor: AppColors.error),
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
        title: const Text('Go Live'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 220,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: AppColors.gradientCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: _previewCamera != null && _previewCamera!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _previewCamera!.value.previewSize?.height ?? 1,
                      height: _previewCamera!.value.previewSize?.width ?? 1,
                      child: CameraPreview(_previewCamera!),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _permissionsGranted ? Icons.videocam : Icons.videocam_off,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _permissionsGranted ? 'Camera ready' : 'Grant camera & mic access',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        if (!_permissionsGranted) ...[
                          const SizedBox(height: 8),
                          TextButton(onPressed: _requestPermissions, child: const Text('Allow Permissions')),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Stream Title', prefixIcon: Icon(Icons.title)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
            items: ['Music', 'Gaming', 'Art', 'Talk', 'AI Battle']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 20),
          const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Allow Gifts'),
            subtitle: const Text('Viewers can send animated gifts'),
            value: _allowGifts,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _allowGifts = v),
          ),
          SwitchListTile(
            title: const Text('Allow Donations'),
            subtitle: const Text('Support button in live room'),
            value: _allowDonations,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _allowDonations = v),
          ),
          SwitchListTile(
            title: const Text('AI Co-host'),
            subtitle: const Text('AI assists during stream'),
            value: _enableAi,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _enableAi = v),
          ),
          SwitchListTile(
            title: const Text('AI Chat Bots'),
            subtitle: const Text('Neural comments in live chat'),
            value: _enableAiBots,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _enableAiBots = v);
              ref.read(aiBotsEnabledProvider.notifier).state = v;
            },
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: _loading ? 'STARTING...' : 'GO LIVE NOW',
            icon: Icons.sensors,
            expanded: true,
            onPressed: _loading ? () {} : _goLive,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.battleSetup),
            icon: const Icon(Icons.flash_on),
            label: const Text('Start AI Battle Instead'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
