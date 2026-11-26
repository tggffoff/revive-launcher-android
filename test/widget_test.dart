import 'package:flutter_test/flutter_test.dart';
import 'package:revive_launcher/screens/login_screen.dart';

void main() {
  testWidgets('login screen displays Discord sign-in', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(authConfigured: false),
      ),
    );

    expect(find.text('REVIVE'), findsOneWidget);
    expect(find.text('SE CONNECTER AVEC DISCORD'), findsOneWidget);
  });
}
