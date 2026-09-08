import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Best-effort: if no Firebase project is configured for this build yet,
  // this fails silently and the app runs normally without push support.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
  } catch (_) {
    // Push notifications stay disabled; everything else still works.
  }

  runApp(const ProviderScope(child: IstTrainerEvaluationApp()));
}
