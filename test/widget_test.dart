import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revive_launcher/screens/login_screen.dart';
import 'package:revive_launcher/services/app_settings.dart';

void main() {
  testWidgets('login screen displays Discord sign-in', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authConfigured: false,
          settings: AppSettings(preference: 'fr'),
        ),
      ),
    );

    expect(find.byKey(const Key('revive-wordmark')), findsOneWidget);
    expect(find.text('SE CONNECTER AVEC DISCORD'), findsOneWidget);
  });

  testWidgets('unsupported phone language falls back to English',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authConfigured: false,
          settings: AppSettings(deviceLanguageOverride: 'de'),
        ),
      ),
    );

    expect(find.text('SIGN IN WITH DISCORD'), findsOneWidget);
  });
}
