import 'package:flutter/material.dart';

import '../config.dart';
import '../models/auth_profile.dart';
import '../models/imported_build.dart';
import '../services/app_settings.dart';
import '../services/links.dart';
import '../widgets/revive_avatar.dart';
import '../widgets/revive_theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.settings,
    required this.profile,
    required this.builds,
    required this.onEditNickname,
    required this.onSignOut,
  });

  final AppSettings settings;
  final AuthProfile profile;
  final List<ImportedBuild> builds;
  final VoidCallback onEditNickname;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final t = settings.tr;
    final totalBytes = builds.fold<int>(
      0,
      (total, build) => total + build.totalBytes,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 3, 18, 25),
      children: <Widget>[
        PageTitle(
          section: t('settings').toUpperCase(),
          title: t('settings'),
        ),
        SectionLabel(t('profile').toUpperCase()),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: revivePanelDecoration(),
          child: Row(
            children: <Widget>[
              ReviveAvatar(url: profile.avatarUrl, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.pseudo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Discord · ${profile.discordName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: reviveMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onEditNickname, child: Text(t('edit'))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
          label: Text(t('signOut')),
        ),
        const SizedBox(height: 20),
        SectionLabel(t('language').toUpperCase()),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: revivePanelDecoration(13),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: settings.preference,
              isExpanded: true,
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'auto',
                  child: Text(t('auto'), overflow: TextOverflow.ellipsis),
                ),
                const DropdownMenuItem<String>(
                  value: 'fr',
                  child: Text('Français'),
                ),
                const DropdownMenuItem<String>(
                  value: 'en',
                  child: Text('English'),
                ),
                const DropdownMenuItem<String>(
                  value: 'es',
                  child: Text('Español'),
                ),
              ],
              onChanged: (value) {
                if (value != null) settings.setPreference(value);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        SectionLabel(t('storage').toUpperCase()),
        const SizedBox(height: 6),
        Text(
          t('storageLine', <String, Object>{
            'count': builds.length,
            'size': formatBytes(totalBytes, settings.language),
          }),
          style: const TextStyle(color: reviveMuted),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => openLink(context, settings, reviveDiscordInvite),
          icon: const Icon(Icons.forum_outlined),
          label: Text(t('community')),
        ),
        const SizedBox(height: 20),
        SectionLabel(t('about').toUpperCase()),
        const SizedBox(height: 6),
        const Text('REVIVE LAUNCHER ANDROID • $reviveVersion'),
        const SizedBox(height: 6),
        Text(
          t('credits'),
          style: const TextStyle(color: reviveMuted, fontSize: 11, height: 1.5),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Revive Launcher',
              applicationVersion: reviveVersion,
            ),
            child: Text(
              MaterialLocalizations.of(context).viewLicensesButtonLabel,
            ),
          ),
        ),
      ],
    );
  }
}
