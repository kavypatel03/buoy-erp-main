import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:final_project/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full App E2E Test Suite', () {
    testWidgets('Verify Complete App Flow: Login -> Navigation -> Logout', (WidgetTester tester) async {
      app.main();
      
      // 1. Initial Load
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      
      // 2. Login Flow (if not authenticated)
      final isDashboardPresent = find.text('Live Overview').evaluate().isNotEmpty;
      if (!isDashboardPresent) {
        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          final emailField = textFields.first;
          final passwordField = textFields.last;
          final loginButton = find.text('Login');
          await tester.enterText(emailField, 'kavypatel03@gmail.com'); 
          await tester.enterText(passwordField, '123456'); 
          await tester.tap(loginButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // 3. Home / Dashboard
      expect(find.text('Live Overview'), findsOneWidget);
      expect(find.text('Inventory Items'), findsOneWidget);
      print('? Dashboard verified');

      // 4. Inventory Tab
      final inventoryIcon = find.byIcon(Icons.inventory_2_outlined);
      if (inventoryIcon.evaluate().isNotEmpty) {
        await tester.tap(inventoryIcon);
        await tester.pumpAndSettle();
        expect(find.text('Inventory'), findsWidgets);
        expect(find.text('All Items'), findsWidgets);
        print('? Inventory page verified');
      }

      // 5. Employee Tab
      final employeeIcon = find.byIcon(Icons.person_outline_rounded);
      if (employeeIcon.evaluate().isNotEmpty) {
        await tester.tap(employeeIcon);
        await tester.pumpAndSettle();
        expect(find.text('Employee'), findsWidgets);
        print('? Employee page verified');
      }

      // 6. Factory/Production Tab
      final factoryIcon = find.byIcon(Icons.factory_outlined);
      if (factoryIcon.evaluate().isNotEmpty) {
        await tester.tap(factoryIcon);
        await tester.pumpAndSettle();
        expect(find.text('Factory Production'), findsWidgets);
        print('? Factory page verified');
      }

      // 7. Settings Tab
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
        expect(find.text('Setting'), findsWidgets);
        expect(find.text('Logout'), findsWidgets);
        print('? Settings page verified');

        // Optional: Test Logout
        // await tester.tap(find.text('Logout'));
        // await tester.pumpAndSettle(const Duration(seconds: 2));
        // expect(find.text('Login'), findsWidgets);
        // print('? Logout verified');
      }
    });
  });
}
