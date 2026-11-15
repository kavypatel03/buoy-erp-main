import 'package:flutter_test/flutter_test.dart';
import 'package:final_project/app/app.dart';

void main() {
  testWidgets('BuoyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BuoyApp());

    // Verify that Factory ERP welcome page text is rendered.
    expect(find.text('Factory ERP'), findsOneWidget);
  });
}
