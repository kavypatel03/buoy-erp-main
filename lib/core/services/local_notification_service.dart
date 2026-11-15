import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  static bool _initialized = false;

  static const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
    'buoy_erp_notifications',
    'Buoy ERP Notifications',
    description: 'Notifications and operational alerts from Buoy ERP Admin',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
          
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(settings: initializationSettings);

      // Create Android Notification Channel explicitly for background/lockscreen alerts
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(defaultChannel);
      }

      _initialized = true;
    } catch (e, stack) {
      print("LocalNotificationService initialize error: $e");
      print(stack);
    }
  }

  static Future<void> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print("🔔 Sending notification request to OS: $title");
    
    // Ensure initialized
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'buoy_erp_notifications',
      'Buoy ERP Notifications',
      channelDescription: 'Notifications and operational alerts from Buoy ERP Admin',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
      print("✅ Notification successfully triggered on OS");
    } catch (e, stack) {
      print("❌ Notification failed to show: $e");
      print(stack);
    }
  }
}
