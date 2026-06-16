import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WPlusApp(),
    ),
  );
}

class WPlusApp extends ConsumerWidget {
  const WPlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appInitProvider);
    ref.watch(pushNotificationServiceProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'W+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
