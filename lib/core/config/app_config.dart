/// App configuration — toggle backend vs mock mode.
abstract final class AppConfig {
  static const useBackend = true;

  /// Render production URL — update after deploy if slug changes.
  static const _renderUrl = 'https://wplus-backend.onrender.com';

  static String get apiBaseUrl => _renderUrl;
  static String get wsBaseUrl => _renderUrl;

  static const demoEmail = 'user@wplus.dev';
  static const demoPassword = 'password123';
}
