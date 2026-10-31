import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/firebase_messaging_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Launch the UI immediately so the app opens instantly with zero freeze
  runApp(const BouyApp());

  // Initialize background services asynchronously in a non-blocking manner
  _initializeBackgroundServices();
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
