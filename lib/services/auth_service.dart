import 'package:supabase_flutter/supabase_flutter.dart';

class ReviveAuthService {
  static const redirectUri = 'revive://auth/callback';

  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange =>
      Supabase.instance.client.auth.onAuthStateChange;

  Future<void> signInWithDiscord() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.discord,
      redirectTo: redirectUri,
    );
  }

  Future<void> signOut() => Supabase.instance.client.auth.signOut();
}
