import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/app_settings.dart';
import '../widgets/revive_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authConfigured,
    required this.settings,
    this.authError,
  });

  final bool authConfigured;
  final AppSettings settings;

  /// Error reported while handling the OAuth return link.
  final Object? authError;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _error;

  String _describe(Object error) => widget.settings.tr(
        'signInFailed',
        <String, Object>{
          'error': error is AuthException ? error.message : error,
        },
      );

  Future<void> _login() async {
    if (!widget.authConfigured || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final opened = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.discord,
        redirectTo: reviveAuthRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _error = widget.settings.tr('browserFailed'));
      }
    } catch (error) {
      if (mounted) setState(() => _error = _describe(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.settings.tr;
    final authError = widget.authError;
    final error = _error ?? (authError == null ? null : _describe(authError));
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.55),
            radius: 1.1,
            colors: <Color>[Color(0xFF2A1250), reviveBackground],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: <Widget>[
                    Image.asset(
                      'assets/images/revive_logo.png',
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: 18),
                    Image.asset(
                      'assets/images/revive_wordmark.png',
                      key: const Key('revive-wordmark'),
                      width: 250,
                      semanticLabel: 'REVIVE',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'LAUNCHER',
                      style: TextStyle(
                        color: reviveLilac,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('tagline'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ReviveButton(
                      label: t('signIn'),
                      icon: Icons.login,
                      busy: _busy,
                      onPressed: widget.authConfigured ? _login : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.authConfigured
                          ? t('signInHint')
                          : t('authNotConfigured'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: reviveMuted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 14),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
