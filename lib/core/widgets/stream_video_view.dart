import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../theme/app_colors.dart';

/// Video layer for live streams — LiveKit when configured, local camera in stub mode.
class StreamVideoView extends StatefulWidget {
  const StreamVideoView({
    super.key,
    required this.token,
    required this.url,
    required this.room,
    required this.isStub,
    this.canPublish = false,
  });

  final String token;
  final String url;
  final String room;
  final bool isStub;
  final bool canPublish;

  @override
  State<StreamVideoView> createState() => _StreamVideoViewState();
}

class _StreamVideoViewState extends State<StreamVideoView> {
  Room? _room;
  CameraController? _camera;
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.isStub) {
      if (widget.canPublish) {
        await _initLocalCamera();
      } else {
        setState(() {
          _connecting = false;
        });
      }
      return;
    }

    try {
      final room = Room();
      await room.connect(widget.url, widget.token);
      if (widget.canPublish) {
        await room.localParticipant?.setCameraEnabled(true);
        await room.localParticipant?.setMicrophoneEnabled(true);
      }
      if (mounted) {
        setState(() {
          _room = room;
          _connecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _connecting = false;
        });
      }
    }
  }

  Future<void> _initLocalCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _connecting = false);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(front, ResolutionPreset.medium, enableAudio: true);
      await controller.initialize();
      if (mounted) {
        setState(() {
          _camera = controller;
          _connecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Camera unavailable';
          _connecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _room?.disconnect();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    if (_camera != null && _camera!.value.isInitialized) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _camera!.value.previewSize?.height ?? 1,
            height: _camera!.value.previewSize?.width ?? 1,
            child: CameraPreview(_camera!),
          ),
        ),
      );
    }

    if (_room != null) {
      final remoteVideo = _room!.remoteParticipants.values
          .expand((p) => p.videoTrackPublications)
          .where((pub) => pub.subscribed && pub.track != null)
          .map((pub) => pub.track!)
          .firstOrNull;

      if (remoteVideo != null) {
        return VideoTrackRenderer(remoteVideo);
      }

      final localVideo = _room!.localParticipant?.videoTrackPublications
          .where((pub) => pub.track != null)
          .map((pub) => pub.track!)
          .firstOrNull;

      if (localVideo != null) {
        return VideoTrackRenderer(localVideo);
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceLight, Colors.black],
        ),
      ),
      child: const Center(
        child: Icon(Icons.live_tv, color: AppColors.textMuted, size: 64),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
