import 'package:flutter/material.dart';

import '../models/imported_build.dart';
import '../services/app_settings.dart';
import '../widgets/artwork.dart';
import '../widgets/build_card.dart';
import '../widgets/revive_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.settings,
    required this.builds,
    required this.importing,
    required this.onImport,
    required this.onViewAll,
    required this.onOpenBuild,
  });

  final AppSettings settings;
  final List<ImportedBuild> builds;
  final bool importing;
  final VoidCallback onImport;
  final VoidCallback onViewAll;
  final ValueChanged<ImportedBuild> onOpenBuild;

  Widget _hero() => Container(
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(minHeight: 230),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: revivePurple.withValues(alpha: .55)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF35145E),
              Color(0xFF1A1D3C),
              Color(0xFF102B45),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -45,
              top: -30,
              child: Opacity(
                opacity: .28,
                child: Image.asset(
                  'assets/images/revive_logo.png',
                  width: 230,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    settings.tr('tagline'),
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    settings.tr('hero'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  ReviveButton(
                    label: settings.tr('import'),
                    icon: Icons.add,
                    busy: importing,
                    onPressed: onImport,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _recent(ImportedBuild build) => InkWell(
        onTap: () => onOpenBuild(build),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 230,
          padding: const EdgeInsets.all(9),
          decoration: revivePanelDecoration(15),
          child: Row(
            children: <Widget>[
              BuildArtwork(version: build.version, width: 90, height: 114),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      build.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      versionLabel(build, settings),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: reviveMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final recent = builds.take(8).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 3, 18, 25),
      children: <Widget>[
        PageTitle(section: 'ANDROID', title: settings.tr('welcome')),
        _hero(),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            Expanded(child: SectionLabel(settings.tr('recent'))),
            TextButton(onPressed: onViewAll, child: Text(settings.tr('view'))),
          ],
        ),
        if (recent.isEmpty)
          EmptyLibrary(settings: settings)
        else
          SizedBox(
            height: 134,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _recent(recent[index]),
            ),
          ),
      ],
    );
  }
}
