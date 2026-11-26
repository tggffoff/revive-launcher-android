import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authConfigured});
  final bool authConfigured;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    if (!widget.authConfigured || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.discord,
        redirectTo: 'revive://auth/callback',
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Connexion Discord impossible : $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/revive_logo.png', width: 92, height: 92, errorBuilder: (_, error, stack) => const Icon(Icons.sports_esports, size: 80, color: Color(0xFFB98AFF))),
                const SizedBox(height: 20),
                const Text('REVIVE', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 5)),
                const Text('LAUNCHER', style: TextStyle(color: Color(0xFFB98AFF), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 4)),
                const SizedBox(height: 12),
                const Text('TES ANCIENNES SAISONS. TON HISTOIRE.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 42),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.authConfigured && !_busy ? _login : null,
                    icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                    label: const Text('SE CONNECTER AVEC DISCORD'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7950D9), padding: const EdgeInsets.symmetric(vertical: 17)),
                  ),
                ),
                if (!widget.authConfigured) ...[
                  const SizedBox(height: 14),
                  const Text('Connexion non configurée : ajoute SUPABASE_URL et SUPABASE_ANON_KEY dans les secrets GitHub Actions, puis active Discord dans Supabase Auth.', textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 11, height: 1.5)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
