import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

const _tokenKey = 'wplus_access_token';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final apiClientProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});

final authTokenProvider = StateNotifierProvider<AuthTokenNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthTokenNotifier(prefs);
});

class AuthTokenNotifier extends StateNotifier<String?> {
  AuthTokenNotifier(this._prefs) : super(_prefs.getString(_tokenKey));

  final SharedPreferences _prefs;

  Future<void> setToken(String? token) async {
    if (token == null) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, token);
    }
    state = token;
  }

  Future<void> clear() => setToken(null);
}
