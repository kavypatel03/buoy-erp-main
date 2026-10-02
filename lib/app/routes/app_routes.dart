import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/main_shell/presentation/pages/main_shell_screen.dart';
import '../../features/notification/presentation/pages/notification_page.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/help_support_page.dart';
import '../../features/settings/presentation/pages/my_profile_page.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String lowStocks = '/low-stocks';
  static const String employee = '/employee';
  static const String settings = '/settings';
  static const String myProfile = '/my-profile';
  static const String changePassword = '/change-password';
  static const String helpSupport = '/help-support';

  static Map<String, WidgetBuilder> get routes => {
        welcome: (context) => const WelcomePage(),
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        dashboard: (context) => const MainShellScreen(initialIndex: 0),
        lowStocks: (context) => const MainShellScreen(initialIndex: 1),
        employee: (context) => const MainShellScreen(initialIndex: 2),
        settings: (context) => const MainShellScreen(initialIndex: 3),
        notifications: (context) => const NotificationPage(),
        myProfile: (context) => const MyProfilePage(),
        changePassword: (context) => const ChangePasswordPage(),
        helpSupport: (context) => const HelpSupportPage(),
      };
}
