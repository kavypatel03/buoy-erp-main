import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/firebase_messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.initialize();
  await FirebaseMessagingService.initialize();
  runApp(const BouyApp());
}
