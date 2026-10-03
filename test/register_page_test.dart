import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('RegisterPage renders without throwing exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: RegisterPage(),
    ));

    // Allow any futures (like checkRegistrationStatus) to resolve
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
  });
}
