import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/launcher_screen.dart';

// These are the existing Revive Supabase project URL and public publishable
// client key from the desktop launcher. They are designed for client apps;
// never put a service_role key or Discord client secret here.
const reviveSupabaseUrl = 'https://sjhsfiijtjzaxtttueon.supabase.co';
const reviveSupabasePublishableKey = 'sb_publishable_nCj7qRHvOtcws6Vc3uDJFA_72l5efpJ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: reviveSupabaseUrl,
    anonKey: reviveSupabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const ReviveApp());
}

class ReviveApp extends StatelessWidget {
  const ReviveApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Revive Launcher',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF080A12),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF963FFF),
        brightness: Brightness.dark,
        surface: const Color(0xFF151827),
      ),
      useMaterial3: true,
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return const LoginScreen(authConfigured: true);
      return LauncherScreen(user: user);
    },
  );
}
