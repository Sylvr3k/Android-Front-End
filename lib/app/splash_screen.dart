import 'package:flutter/material.dart';

/// Shown only while the app is checking for a previously-stored session
/// (`AuthController.build()` resolving). This is deliberately the only
/// thing that can be on screen during that window — nothing that assumes
/// "the user is signed in" (Home, the bottom nav shell, notifications) is
/// allowed to mount before we actually know that, otherwise those screens
/// fire authenticated API calls with no token yet and land in a permanent
/// error state. See router.dart's redirect logic.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                'IST',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
