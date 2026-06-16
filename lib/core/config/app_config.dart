import 'dart:io';

/// App configuration — toggle backend vs mock mode.
abstract final class AppConfig {
  /// Set to true to use real backend API + WebSocket.
  static const useBackend = true;

  /// Backend base URL. Use 10.0.2.2 for Android emulator, localhost for iOS sim.
  static String get apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get wsBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Demo login credentials (seed data).
  static const demoEmail = 'user@wplus.dev';
  static const demoPassword = 'password123';
}
