import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'l10n/strings.dart';
import 'screens/launcher_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_settings.dart';
import 'services/secure_session_storage.dart';
import 'widgets/revive_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const <String>['ATLAS Link'],
      await rootBundle.loadString('third_party/ATLAS-Link-LICENSE.txt'),
    );
  });
  final settings = await AppSettings.load();
  var authReady = true;
  try {
    await Supabase.initialize(
      url: reviveSupabaseUrl,
      anonKey: reviveSupabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureSessionStorage(),
      ),
    );
  } catch (error) {
    debugPrint('Supabase initialisation failed: $error');
    authReady = false;
  }
  runApp(ReviveApp(settings: settings, authReady: authReady));
}

class ReviveApp extends StatelessWidget {
  const ReviveApp({super.key, required this.settings, required this.authReady});

  final AppSettings settings;
  final bool authReady;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Revive Launcher',
          debugShowCheckedModeBanner: false,
          theme: reviveTheme(),
          locale: Locale(settings.language),
          supportedLocales: <Locale>[
            for (final code in supportedLanguages) Locale(code),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: authReady
              ? AuthGate(settings: settings)
              : LoginScreen(authConfigured: false, settings: settings),
        ),
      );
}

/// Shows the launcher only with a Discord session, restored at startup.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            return LoginScreen(
              authConfigured: true,
              settings: settings,
              authError: snapshot.error,
            );
          }
          return LauncherScreen(
            key: ValueKey<String>(user.id),
            user: user,
            settings: settings,
          );
        },
      );
}
