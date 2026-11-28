import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_settings.dart';

/// Opens a web page in the phone's browser.
Future<void> openLink(
  BuildContext context,
  AppSettings settings,
  String value,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(settings.tr('invalidLink'))),
    );
    return;
  }
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text(settings.tr('linkFailed'))),
    );
  }
}

/// YouTube search used when a build has no trailer link.
String trailerSearchUrl(String query) => Uri.https(
      'www.youtube.com',
      '/results',
      <String, String>{'search_query': 'Fortnite $query trailer'},
    ).toString();
