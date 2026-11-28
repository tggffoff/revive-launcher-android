import 'dart:io';

import 'package:flutter/material.dart';

import '../models/imported_build.dart';
import '../services/app_settings.dart';
import 'artwork.dart';
import 'revive_theme.dart';

String versionLabel(ImportedBuild build, AppSettings settings) =>
    build.version.isEmpty ? settings.tr('unknownVersion') : build.version;

String buildSummary(ImportedBuild build, AppSettings settings) =>
    '${formatBytes(build.totalBytes, settings.language)} • '
    '${settings.tr('files', <String, Object>{'count': build.fileCount})}';

class BuildCard extends StatelessWidget {
  const BuildCard({
    super.key,
    required this.item,
    required this.settings,
    required this.onTap,
  });

  final ImportedBuild item;
  final AppSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final missing = !Directory(item.directory).existsSync();
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: revivePanelDecoration(),
          child: Row(
            children: <Widget>[
              BuildArtwork(version: item.version, width: 96, height: 84),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      versionLabel(item, settings),
                      style: const TextStyle(color: reviveMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      missing
                          ? settings.tr('missingFiles')
                          : buildSummary(item, settings),
                      style: TextStyle(
                        color: missing ? Colors.orangeAccent : reviveLilac,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: reviveMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
        decoration: revivePanelDecoration(),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.inventory_2_outlined,
              color: reviveMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              settings.tr('empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              settings.tr('emptyHint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: reviveMuted, fontSize: 11),
            ),
          ],
        ),
      );
}
