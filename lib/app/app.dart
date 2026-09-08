import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/notifications/push_notification_provider.dart';
import '../features/authentication/presentation/providers/auth_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class IstTrainerEvaluationApp extends ConsumerWidget {
  const IstTrainerEvaluationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.valueOrNull != null) {
        ref.read(pushNotificationServiceProvider).initialize();
      }
    });

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
