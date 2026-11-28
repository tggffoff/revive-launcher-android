/// Discord profile as stored by Supabase. The name resolution order mirrors the
/// desktop launcher (`revive_supabase_auth.dart`).
class AuthProfile {
  const AuthProfile({
    required this.pseudo,
    required this.discordName,
    required this.avatarUrl,
  });

  /// Editable nickname (`user_metadata.pseudo`), else the Discord name.
  final String pseudo;
  final String discordName;

  /// Empty when Discord did not provide an https avatar.
  final String avatarUrl;

  factory AuthProfile.fromMetadata(
    Map<String, dynamic>? metadata, {
    String? email,
  }) {
    final data = metadata ?? const <String, dynamic>{};
    final claims = data['custom_claims'];
    final emailName =
        email != null && email.contains('@') ? email.split('@').first : null;
    final discordName = _firstText(<Object?>[
      claims is Map ? claims['global_name'] : null,
      data['global_name'],
      data['full_name'],
      data['name'],
      data['preferred_username'],
      emailName,
      'Player',
    ]);
    final avatar = _firstText(<Object?>[data['avatar_url'], data['picture']]);
    return AuthProfile(
      pseudo: _firstText(<Object?>[data['pseudo'], discordName]),
      discordName: discordName,
      avatarUrl: avatar.startsWith('https://') ? avatar : '',
    );
  }

  static String _firstText(List<Object?> candidates) {
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return '';
  }
}
