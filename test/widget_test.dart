import 'package:flutter_test/flutter_test.dart';
import 'package:revive_launcher/main.dart';

void main() {
  testWidgets('app displays Discord login when auth is not configured', (tester) async {
    await tester.pumpWidget(const ReviveApp(authConfigured: false));
    expect(find.text('REVIVE'), findsOneWidget);
    expect(find.text('SE CONNECTER AVEC DISCORD'), findsOneWidget);
  });
}
