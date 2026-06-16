import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Push notification service — stub implementation.
/// To activate: add firebase_messaging + flutter_local_notifications to pubspec.yaml,
/// add google-services.json (Android) and GoogleService-Info.plist (iOS),
/// then replace this stub with real Firebase calls.
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  service.init();
  return service;
});

class PushNotificationService {
  String? _token;

  String? get token => _token;

  Future<void> init() async {
    // Stub — real implementation uses FirebaseMessaging.instance
    debugPrint('[Push] Notification service initialized (stub)');
  }

  Future<String?> getToken() async {
    // Real: return await FirebaseMessaging.instance.getToken();
    return _token;
  }

  Future<void> subscribeToTopic(String topic) async {
    // Real: await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[Push] Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('[Push] Unsubscribed from topic: $topic');
  }

  void showLocalNotification({required String title, required String body}) {
    // Real: use FlutterLocalNotificationsPlugin
    debugPrint('[Push] Local notification: $title — $body');
  }
}
