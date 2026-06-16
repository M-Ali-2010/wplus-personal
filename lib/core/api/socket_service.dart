import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../models/stream.dart';
import '../models/user.dart';

typedef StreamCommentCallback = void Function(StreamComment comment);
typedef StreamGiftCallback = void Function(Map<String, dynamic> gift);
typedef StreamDonationCallback = void Function(Map<String, dynamic> donation);
typedef StreamPaidMessageCallback = void Function(Map<String, dynamic> message);
typedef ViewerCountCallback = void Function(int count);

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.dispose);
  return service;
});

class SocketService {
  SocketService();

  io.Socket? _socket;
  String? _currentStreamId;
  bool _handlersAttached = false;

  final List<StreamCommentCallback> _commentListeners = [];
  final List<StreamGiftCallback> _giftListeners = [];
  final List<StreamDonationCallback> _donationListeners = [];
  final List<StreamPaidMessageCallback> _paidMessageListeners = [];
  final List<ViewerCountCallback> _viewerCountListeners = [];

  // Legacy single-callback API (adds to listener list)
  set onComment(StreamCommentCallback? cb) {
    _commentListeners.clear();
    if (cb != null) _commentListeners.add(cb);
  }

  set onGift(StreamGiftCallback? cb) {
    _giftListeners.clear();
    if (cb != null) _giftListeners.add(cb);
  }

  set onDonation(StreamDonationCallback? cb) {
    _donationListeners.clear();
    if (cb != null) _donationListeners.add(cb);
  }

  set onViewerCount(ViewerCountCallback? cb) {
    _viewerCountListeners.clear();
    if (cb != null) _viewerCountListeners.add(cb);
  }

  void addCommentListener(StreamCommentCallback cb) => _commentListeners.add(cb);
  void removeCommentListener(StreamCommentCallback cb) => _commentListeners.remove(cb);
  void addGiftListener(StreamGiftCallback cb) => _giftListeners.add(cb);
  void removeGiftListener(StreamGiftCallback cb) => _giftListeners.remove(cb);

  void connect(String streamId) {
    if (_socket != null && _currentStreamId == streamId) return;

    if (_socket != null) {
      _socket!.emit('stream.leave', {'streamId': _currentStreamId});
      _socket!.dispose();
      _socket = null;
      _handlersAttached = false;
    }

    _currentStreamId = streamId;
    _socket = io.io(
      '${AppConfig.wsBaseUrl}/streams',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _attachHandlers();

    _socket!.onConnect((_) {
      _socket!.emit('stream.join', {'streamId': streamId});
    });
  }

  void _attachHandlers() {
    if (_socket == null || _handlersAttached) return;
    _handlersAttached = true;

    _socket!.on('stream.comment', (data) {
      if (data is Map) {
        final comment = _mapComment(Map<String, dynamic>.from(data));
        for (final cb in List<StreamCommentCallback>.from(_commentListeners)) {
          cb(comment);
        }
      }
    });

    _socket!.on('stream.gift', (data) {
      if (data is Map) {
        final gift = Map<String, dynamic>.from(data);
        for (final cb in List<StreamGiftCallback>.from(_giftListeners)) {
          cb(gift);
        }
      }
    });

    _socket!.on('stream.donation', (data) {
      if (data is Map) {
        final donation = Map<String, dynamic>.from(data);
        for (final cb in List<StreamDonationCallback>.from(_donationListeners)) {
          cb(donation);
        }
      }
    });

    _socket!.on('stream.paid_message', (data) {
      if (data is Map) {
        final msg = Map<String, dynamic>.from(data);
        for (final cb in List<StreamPaidMessageCallback>.from(_paidMessageListeners)) {
          cb(msg);
        }
      }
    });

    _socket!.on('stream.viewer_count', (data) {
      if (data is Map && data['count'] != null) {
        final count = (data['count'] as num).toInt();
        for (final cb in List<ViewerCountCallback>.from(_viewerCountListeners)) {
          cb(count);
        }
      }
    });
  }

  void disconnect() {
    if (_socket != null && _currentStreamId != null) {
      _socket!.emit('stream.leave', {'streamId': _currentStreamId});
    }
    _socket?.dispose();
    _socket = null;
    _currentStreamId = null;
    _handlersAttached = false;
  }

  void dispose() => disconnect();

  StreamComment _mapComment(Map<String, dynamic> c) {
    final user = c['user'] as Map<String, dynamic>? ?? {};
    return StreamComment(
      id: c['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      user: UserProfile(
        id: user['id'] as String? ?? '',
        username: user['username'] as String? ?? '',
        displayName: user['displayName'] as String? ?? 'User',
      ),
      text: c['text'] as String? ?? '',
      createdAt: c['createdAt'] != null
          ? DateTime.parse(c['createdAt'] as String)
          : DateTime.now(),
      isAi: c['isAi'] as bool? ?? false,
      isGift: c['isGift'] as bool? ?? false,
      isPaid: c['isPaid'] as bool? ?? false,
    );
  }
}
