import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps Firebase Cloud Messaging + local notification display.
///
/// This degrades gracefully: if no Firebase project has been configured
/// for this build (no `google-services.json` / no generated
/// `firebase_options.dart`), every method here catches its own failure,
/// logs it, and does nothing further — the rest of the app (including the
/// in-app notification center backed by the Laravel API) keeps working
/// normally. See the README for how to wire up a real Firebase project.
class PushNotificationService {
  PushNotificationService(this._onTokenRefreshed);

  final void Function(String token) _onTokenRefreshed;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      developer.log('Firebase not configured — push notifications disabled.', name: 'PushNotificationService', error: e);
      return;
    }

    try {
      await _initializeLocalNotifications();

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) _onTokenRefreshed(token);

      messaging.onTokenRefresh.listen(_onTokenRefreshed);

      // App in foreground: FCM does not show a system notification for us,
      // so we render one via flutter_local_notifications.
      FirebaseMessaging.onMessage.listen(_showLocalNotification);

      _initialized = true;
    } catch (e) {
      developer.log('Failed to initialize push notifications.', name: 'PushNotificationService', error: e);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'ist_evaluations',
      'IST Evaluations',
      channelDescription: 'Evaluation, announcement and account notifications from IST.',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
    );
  }
}

/// Must be a top-level function: this is invoked by the platform in a
/// separate isolate when a push arrives while the app is fully
/// backgrounded/terminated.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // No Firebase project configured for this build — nothing to do.
  }
}
