import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class BouyApp extends StatelessWidget {
  const BouyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: AppRoutes.welcome,
          routes: AppRoutes.routes,
        );
      },
    );
  }

}
