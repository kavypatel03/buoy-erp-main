import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint("Handling background FCM message: ${message.messageId}");

    final title = message.notification?.title ?? message.data['title'] ?? 'Buoy ERP Alert';
    final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

    if (title.isNotEmpty || body.isNotEmpty) {
      await LocalNotificationService.initialize();
      await LocalNotificationService.showNotification(
        id: (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF,
        title: title,
        body: body,
      );
    }
  } catch (e) {
    debugPrint("Background FCM message error: $e");
  }
}

class FirebaseMessagingService {
  static FirebaseMessaging? _firebaseMessaging;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted notification permission');
        
        // Sync FCM device token immediately
        await syncToken();

        // Listen for token refresh
        _firebaseMessaging!.onTokenRefresh.listen((newToken) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', newToken);
          await AuthService.updateFcmToken(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Foreground FCM message received: ${message.messageId}');
          
          final title = message.notification?.title ?? message.data['title'] ?? 'Buoy ERP Alert';
          final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

          if (title.isNotEmpty || body.isNotEmpty) {
            LocalNotificationService.showNotification(
              id: (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF,
              title: title,
              body: body,
            );
          }
        });
      }
    } catch (e) {
      debugPrint("FirebaseMessagingService init skipped or failed: $e");
    }
  }

  /// Syncs current device token with backend and stores locally
  static Future<void> syncToken() async {
    if (kIsWeb) return;
    try {
      if (_firebaseMessaging == null) {
        await Firebase.initializeApp();
        _firebaseMessaging = FirebaseMessaging.instance;
      }

      final token = await _firebaseMessaging?.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        await AuthService.updateFcmToken(token);
        debugPrint('FCM Token synced to backend');
      }
    } catch (e) {
      debugPrint('FCM Token sync error: $e');
    }
  }
}
