import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/task_provider.dart';

void main() {
  testWidgets('Daily task app login screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TaskProvider()),
        ],
        child: const DailyTaskApp(),
      ),
    );

    // Verify that our login title starts on screen.
    expect(find.text('Daily Tasks'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
