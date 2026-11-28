import 'package:flutter/material.dart';

import '../models/imported_build.dart';
import '../services/app_settings.dart';
import '../widgets/build_card.dart';
import '../widgets/revive_theme.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({
    super.key,
    required this.settings,
    required this.builds,
    required this.onOpenBuild,
  });

  final AppSettings settings;
  final List<ImportedBuild> builds;
  final ValueChanged<ImportedBuild> onOpenBuild;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final query = _query.toLowerCase().trim();
    final matches = widget.builds
        .where(
          (build) =>
              '${build.name} ${build.version}'.toLowerCase().contains(query),
        )
        .toList();
    return ListView(
      // Bottom space so the "+" button never hides the last card.
      padding: const EdgeInsets.fromLTRB(18, 3, 18, 96),
      children: <Widget>[
        PageTitle(
          section: settings.tr('library').toUpperCase(),
          title: settings.tr('myBuilds'),
        ),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: settings.tr('search'),
            filled: true,
            fillColor: revivePanel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SectionLabel(
          settings.tr('buildCount', <String, Object>{'count': matches.length}),
        ),
        const SizedBox(height: 10),
        if (widget.builds.isEmpty)
          EmptyLibrary(settings: settings)
        else if (matches.isEmpty)
          Text(
            settings.tr('noResult'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: reviveMuted),
          )
        else
          for (final build in matches)
            BuildCard(
              item: build,
              settings: settings,
              onTap: () => widget.onOpenBuild(build),
            ),
      ],
    );
  }
}
