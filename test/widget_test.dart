// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:byte_plus/services/theme_service.dart';
import 'package:byte_plus/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Create a ThemeService for testing
    final themeService = ThemeService();
    await themeService.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(themeService: themeService));

    // Verify the app renders without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
