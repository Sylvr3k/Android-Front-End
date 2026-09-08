import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ist_trainer_evaluation/core/providers.dart';
import 'package:ist_trainer_evaluation/core/storage/secure_storage.dart';
import 'package:ist_trainer_evaluation/features/authentication/presentation/screens/login_screen.dart';

/// Widget tests must never touch the real platform secure-storage channel
/// (there is no platform to answer it) — this in-memory stand-in keeps the
/// session-restoration logic exercised without a real plugin.
class _FakeSecureStorage implements SecureStorage {
  String? _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> clearToken() async => _token = null;
}

void main() {
  testWidgets('login screen requires both fields before submitting', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStorageProvider.overrideWithValue(_FakeSecureStorage())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Email or Admission Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Required'), findsWidgets);
  });
}
