import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisyarat/main.dart';
import 'package:hisyarat/core/constants.dart';

void main() {
  group('HiSyarat App Smoke Tests', () {
    testWidgets('App launches with splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HiSyaratApp());
      // Splash screen should show app name
      expect(find.text(AppConstants.appName), findsOneWidget);
    });

    testWidgets('Splash screen shows tagline', (WidgetTester tester) async {
      await tester.pumpWidget(const HiSyaratApp());
      expect(find.text(AppConstants.appTagline), findsOneWidget);
    });

    testWidgets('Splash screen shows theme badge', (WidgetTester tester) async {
      await tester.pumpWidget(const HiSyaratApp());
      expect(find.text(AppConstants.appTheme), findsOneWidget);
    });

    testWidgets('Splash screen shows loading indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const HiSyaratApp());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
