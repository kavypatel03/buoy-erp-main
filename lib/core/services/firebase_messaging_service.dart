import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint("Handling a background message: ${message.messageId}");
  } catch (e) {
    debugPrint("Background message error: $e");
  }
}

class FirebaseMessagingService {
  static FirebaseMessaging? _firebaseMessaging;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permissions asynchronously
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
        
        // Get the token safely with a timeout
        try {
          String? token = await _firebaseMessaging!.getToken().timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );
          if (token != null) {
            debugPrint('FCM Token retrieved successfully');
            // Send this token to backend
            await AuthService.updateFcmToken(token);
          }
        } catch (e) {
          debugPrint('Failed to get FCM token: $e');
        }

        // Listen to token refresh
        _firebaseMessaging!.onTokenRefresh.listen((newToken) {
          AuthService.updateFcmToken(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          
          if (message.notification != null) {
            LocalNotificationService.showNotification(
              id: message.messageId.hashCode & 0x7FFFFFFF,
              title: message.notification!.title ?? 'Notification',
              body: message.notification!.body ?? '',
            );
          }
        });
      }
    } catch (e) {
      debugPrint("FirebaseMessagingService init skipped or failed: $e");
    }
  }
}
