import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/firebase_messaging_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Launch the UI immediately so the app opens instantly with zero freeze
  runApp(const BuoyApp());

  // Initialize background services asynchronously in a non-blocking manner
  if (!kIsWeb) {
    _initializeBackgroundServices();
  }
}

Future<void> _initializeBackgroundServices() async {
  try {
    await LocalNotificationService.initialize();
  } catch (e) {
    debugPrint('LocalNotificationService error: $e');
  }

  try {
    await FirebaseMessagingService.initialize();
  } catch (e) {
    debugPrint('FirebaseMessagingService error: $e');
  }
}
