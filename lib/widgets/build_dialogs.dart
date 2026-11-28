import 'package:flutter/material.dart';

import '../models/imported_build.dart';
import '../services/app_settings.dart';
import '../services/links.dart';
import 'artwork.dart';
import 'build_card.dart';
import 'revive_theme.dart';

/// Owns its text controllers so they outlive the closing animation.
class EditBuildDialog extends StatefulWidget {
  const EditBuildDialog({
    super.key,
    required this.initial,
    required this.settings,
  });

  final ImportedBuild initial;
  final AppSettings settings;

  @override
  State<EditBuildDialog> createState() => _EditBuildDialogState();
}

class _EditBuildDialogState extends State<EditBuildDialog> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _version = TextEditingController(text: widget.initial.version);
  late final _description =
      TextEditingController(text: widget.initial.description);
  late final _trailer =
      TextEditingController(text: widget.initial.trailerUrl);

  @override
  void dispose() {
    _name.dispose();
    _version.dispose();
    _description.dispose();
    _trailer.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    Navigator.pop(
      context,
      widget.initial.copyWith(
        name: name.isEmpty ? widget.initial.name : name,
        version: _version.text.trim(),
        description: _description.text.trim(),
        trailerUrl: _trailer.text.trim(),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String key, {
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: widget.settings.tr(key),
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.settings.tr('edit')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 5),
              _field(_name, 'name'),
              _field(_version, 'version'),
              _field(_description, 'description', maxLines: 3),
              _field(_trailer, 'trailer'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.settings.tr('cancel')),
          ),
          FilledButton(
            onPressed: _save,
            child: Text(widget.settings.tr('save')),
          ),
        ],
      );
}

class NicknameDialog extends StatefulWidget {
  const NicknameDialog({
    super.key,
    required this.initial,
    required this.settings,
  });

  final String initial;
  final AppSettings settings;

  @override
  State<NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<NicknameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.settings.tr('nickname')),
        content: TextField(
          controller: _controller,
          maxLength: 32,
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.settings.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: Text(widget.settings.tr('save')),
          ),
        ],
      );
}

/// Details of an imported build.
class BuildSheet extends StatelessWidget {
  const BuildSheet({
    super.key,
    required this.item,
    required this.settings,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  final ImportedBuild item;
  final AppSettings settings;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = settings.tr;
    final structure = <String>[
      if (item.hasEngine) 'Engine',
      if (item.hasFortniteGame) 'FortniteGame',
    ].join(' + ');
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BuildArtwork(
              version: item.version,
              width: double.infinity,
              height: 150,
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              versionLabel(item, settings),
              style: const TextStyle(color: reviveMuted),
            ),
            const SizedBox(height: 4),
            Text(
              buildSummary(item, settings),
              style: const TextStyle(color: reviveLilac, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              item.description.isEmpty
                  ? t('defaultDescription')
                  : item.description,
              style: const TextStyle(color: reviveMuted, height: 1.4),
            ),
            if (structure.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                t('structure', <String, Object>{'value': structure}),
                style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
              ),
            ],
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () => openLink(
                context,
                settings,
                item.trailerUrl.isNotEmpty
                    ? item.trailerUrl
                    : trailerSearchUrl(
                        item.version.isNotEmpty
                            ? item.version
                            : item.name,
                      ),
              ),
              icon: const Icon(Icons.ondemand_video),
              label: Text(
                t(item.trailerUrl.isNotEmpty
                    ? 'trailerOpen'
                    : 'trailerSearch'),
              ),
            ),
            const SizedBox(height: 8),
            ReviveButton(
              label: t('play'),
              icon: Icons.play_arrow,
              onPressed: onPlay,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(t('edit')),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(t('delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
