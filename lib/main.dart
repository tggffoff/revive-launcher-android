import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/launcher_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  final configured = url.startsWith('https://') && key.isNotEmpty;
  if (configured) {
    await Supabase.initialize(url: url, anonKey: key);
  }
  runApp(ReviveApp(authConfigured: configured));
}

class ReviveApp extends StatelessWidget {
  const ReviveApp({super.key, required this.authConfigured});
  final bool authConfigured;

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
    home: authConfigured ? const AuthGate() : const LoginScreen(authConfigured: false),
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
