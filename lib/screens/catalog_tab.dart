import 'package:flutter/material.dart';

import '../config.dart';
import '../models/imported_build.dart';
import '../services/app_settings.dart';
import '../services/fortforge_service.dart';
import '../services/links.dart';
import '../widgets/artwork.dart';
import '../widgets/revive_theme.dart';

/// Build sources and the FortForge Android catalog.
class CatalogTab extends StatefulWidget {
  const CatalogTab({
    super.key,
    required this.settings,
    required this.service,
    required this.onImport,
  });

  final AppSettings settings;
  final FortForgeService service;
  final VoidCallback onImport;

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  late Future<CatalogResult> _future = widget.service.load();
  String _query = '';

  String _t(String key, [Map<String, Object> args = const <String, Object>{}]) =>
      widget.settings.tr(key, args);

  Future<void> _refresh() async {
    final next = widget.service.load(refresh: true);
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder displays the error.
    }
  }

  Widget _source(String asset, String title, String subtitle, String url) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: InkWell(
          onTap: () => openLink(context, widget.settings, url),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: revivePanelDecoration(14),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(asset, width: 40, height: 40),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: reviveMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, color: reviveMuted),
              ],
            ),
          ),
        ),
      );

  String _details(CatalogBuild build) => <String>[
        if (build.version.isNotEmpty) build.version,
        if (build.sizeBytes > 0)
          formatBytes(build.sizeBytes, widget.settings.language),
      ].join(' • ');

  void _open(CatalogBuild build) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: revivePanel,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              BuildArtwork(
                version: build.version,
                imageUrl: build.thumbnailUrl,
                width: double.infinity,
                height: 170,
              ),
              const SizedBox(height: 12),
              Text(
                build.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              for (final line in <String>[
                _details(build),
                if (build.releaseDate.length >= 10)
                  _t('releaseDate', <String, Object>{
                    'value': build.releaseDate.substring(0, 10),
                  }),
                if (build.downloadCount > 0)
                  _t('downloads', <String, Object>{
                    'count': build.downloadCount,
                  }),
                if (build.tags.isNotEmpty)
                  _t('tags', <String, Object>{'value': build.tags.join(', ')}),
              ])
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: const TextStyle(color: reviveMuted),
                    ),
                  ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => openLink(
                  sheetContext,
                  widget.settings,
                  trailerSearchUrl(
                    build.version.isNotEmpty ? build.version : build.title,
                  ),
                ),
                icon: const Icon(Icons.ondemand_video),
                label: Text(_t('trailerSearch')),
              ),
              const SizedBox(height: 8),
              ReviveButton(
                label: _t('openFortforge'),
                icon: Icons.open_in_new,
                onPressed: () => openLink(
                  sheetContext,
                  widget.settings,
                  fortForgeAndroidUrl,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.onImport();
                },
                icon: const Icon(Icons.file_upload_outlined),
                label: Text(_t('import')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(CatalogBuild build) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _open(build),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: revivePanelDecoration(),
            child: Row(
              children: <Widget>[
                BuildArtwork(
                  version: build.version,
                  imageUrl: build.thumbnailUrl,
                  width: 108,
                  height: 70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        build.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _details(build),
                        style: const TextStyle(
                          color: reviveLilac,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<CatalogResult>(
        future: _future,
        builder: (context, snapshot) {
          final result = snapshot.data;
          final loading = snapshot.connectionState != ConnectionState.done;
          final query = _query.toLowerCase().trim();
          final builds = (result?.builds ?? const <CatalogBuild>[])
              .where(
                (build) => '${build.title} ${build.version}'
                    .toLowerCase()
                    .contains(query),
              )
              .toList();
          final header = <Widget>[
            PageTitle(
              section: _t('archives').toUpperCase(),
              title: _t('archives'),
            ),
            Text(
              _t('archivesHint'),
              style: const TextStyle(color: reviveMuted, height: 1.5),
            ),
            const SizedBox(height: 14),
            SectionLabel(_t('sources')),
            const SizedBox(height: 9),
            _source(
              'assets/images/fortforge.png',
              'FortForge',
              _t('fortforgeAndroid'),
              fortForgeAndroidUrl,
            ),
            _source(
              'assets/images/carbon.png',
              'Carbon',
              _t('otherArchive'),
              carbonArchiveUrl,
            ),
            _source(
              'assets/images/helix.png',
              'Helix',
              _t('otherArchive'),
              helixArchiveUrl,
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: widget.onImport,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(_t('import')),
            ),
            const SizedBox(height: 18),
            SectionLabel(_t('catalog')),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: _t('search'),
                filled: true,
                fillColor: revivePanel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError) ...<Widget>[
              Text(
                _t('catalogError'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: Text(_t('retry')),
              ),
            ] else ...<Widget>[
              if (result != null && result.fromCache) ...<Widget>[
                Text(
                  _t('catalogCached'),
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
                const SizedBox(height: 8),
              ],
              if (builds.isEmpty)
                Text(
                  _t('noResult'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: reviveMuted),
                ),
            ],
          ];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 3, 18, 25),
              itemCount: header.length + builds.length,
              itemBuilder: (context, index) => index < header.length
                  ? header[index]
                  : _card(builds[index - header.length]),
            ),
          );
        },
      );
}
