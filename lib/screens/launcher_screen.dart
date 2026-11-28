import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_profile.dart';
import '../models/imported_build.dart';
import '../services/app_settings.dart';
import '../services/build_archive_service.dart';
import '../services/build_library.dart';
import '../services/fortforge_service.dart';
import '../services/zip_import.dart';
import '../widgets/build_dialogs.dart';
import '../widgets/revive_avatar.dart';
import '../widgets/revive_theme.dart';
import 'catalog_tab.dart';
import 'home_tab.dart';
import 'library_tab.dart';
import 'settings_tab.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({
    super.key,
    required this.user,
    required this.settings,
  });

  final User user;
  final AppSettings settings;

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  final _archive = BuildArchiveService();
  final _library = BuildLibrary();
  final _catalog = FortForgeService();
  final _builds = <ImportedBuild>[];
  int _tab = 0;
  bool _loading = true;
  bool _importing = false;

  /// `null` while the picker is copying or the archive is being checked.
  double? _progress;

  String _t(String key, [Map<String, Object> args = const <String, Object>{}]) =>
      widget.settings.tr(key, args);

  AuthProfile get _profile => AuthProfile.fromMetadata(
        widget.user.userMetadata,
        email: widget.user.email,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _archive.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    var builds = <ImportedBuild>[];
    try {
      builds = await _library.load();
      await _archive.cleanIncompleteImports();
    } catch (error) {
      debugPrint('Library loading failed: $error');
    }
    if (!mounted) return;
    setState(() {
      _builds.addAll(builds);
      _loading = false;
    });
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _import() async {
    if (_loading || _importing) return;
    setState(() {
      _importing = true;
      _progress = null;
    });
    ImportedBuild? added;
    try {
      added = await _archive.pickAndImportZip(
        existing: List<ImportedBuild>.of(_builds),
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      if (added != null) {
        _builds.insert(0, added);
        await _library.save(_builds);
        if (mounted) {
          setState(() => _tab = 1);
          _toast(_t('imported'));
        }
      }
    } on ZipImportException catch (error) {
      debugPrint('$error');
      if (mounted) _toast(_t('zip_${error.error.name}'));
    } catch (error) {
      debugPrint('Import failed: $error');
      if (mounted) _toast(_t('zip_io'));
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
          _progress = null;
        });
      }
    }
    if (added != null && mounted) await _editBuild(added);
  }

  Future<void> _editBuild(ImportedBuild build) async {
    final result = await showDialog<ImportedBuild>(
      context: context,
      builder: (_) =>
          EditBuildDialog(initial: build, settings: widget.settings),
    );
    if (result == null || !mounted) return;
    final index = _builds.indexWhere((item) => item.id == result.id);
    if (index < 0) return;
    setState(() => _builds[index] = result);
    await _library.save(_builds);
  }

  Future<void> _deleteBuild(ImportedBuild build) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('deleteTitle')),
        content: Text(
          _t('deleteMessage', <String, Object>{'name': build.name}),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _archive.deleteBuild(build);
    } catch (error) {
      debugPrint('Delete failed: $error');
      if (mounted) _toast(_t('deleteFailed'));
      return;
    }
    _builds.removeWhere((item) => item.id == build.id);
    await _library.save(_builds);
    if (mounted) setState(() {});
  }

  void _openBuild(ImportedBuild build) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: revivePanel,
      isScrollControlled: true,
      builder: (sheetContext) => BuildSheet(
        item: build,
        settings: widget.settings,
        onPlay: () {
          Navigator.pop(sheetContext);
          _toast(_t('playInfo'));
        },
        onEdit: () {
          Navigator.pop(sheetContext);
          _editBuild(build);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _deleteBuild(build);
        },
      ),
    );
  }

  Future<void> _editNickname() async {
    final current = _profile.pseudo;
    final value = await showDialog<String>(
      context: context,
      builder: (_) =>
          NicknameDialog(initial: current, settings: widget.settings),
    );
    if (value == null || value.isEmpty || value == current) return;
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{'pseudo': value}),
      );
      if (mounted) _toast(_t('nicknameSaved'));
    } catch (error) {
      debugPrint('Nickname update failed: $error');
      if (mounted) _toast(_t('nicknameFailed'));
    }
  }

  Future<void> _signOut() async {
    _archive.cancel();
    final messenger = ScaffoldMessenger.of(context);
    final failure = _t('signOutFailed');
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      debugPrint('Sign out failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Row(
          children: <Widget>[
            Image.asset(
              'assets/images/revive_logo.png',
              width: 44,
              height: 44,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Image.asset(
                  'assets/images/revive_wordmark.png',
                  width: 108,
                  semanticLabel: 'REVIVE',
                ),
                const SizedBox(height: 2),
                const Text(
                  'LAUNCHER',
                  style: TextStyle(
                    fontSize: 9,
                    color: reviveLilac,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _tab = 3),
              child: ReviveAvatar(url: _profile.avatarUrl, size: 38),
            ),
          ],
        ),
      );

  Widget _importBanner() {
    final progress = _progress;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.all(12),
      decoration: revivePanelDecoration(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  progress == null
                      ? _t('preparing')
                      : _t('extracting', <String, Object>{
                          'percent': (progress * 100).floor(),
                        }),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (progress != null)
                TextButton(
                  onPressed: _archive.cancel,
                  child: Text(_t('cancel')),
                ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 6),
          Text(
            _t('keepOpen'),
            style: const TextStyle(color: reviveMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _page() => switch (_tab) {
        0 => HomeTab(
            settings: widget.settings,
            builds: _builds,
            importing: _importing,
            onImport: _import,
            onViewAll: () => setState(() => _tab = 1),
            onOpenBuild: _openBuild,
          ),
        1 => LibraryTab(
            settings: widget.settings,
            builds: _builds,
            onOpenBuild: _openBuild,
          ),
        2 => CatalogTab(
            settings: widget.settings,
            service: _catalog,
            onImport: _import,
          ),
        _ => SettingsTab(
            settings: widget.settings,
            profile: _profile,
            builds: _builds,
            onEditNickname: _editNickname,
            onSignOut: _signOut,
          ),
      };

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _tab == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _tab = 0);
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                _header(),
                if (_importing) _importBanner(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _page(),
                ),
              ],
            ),
          ),
          floatingActionButton: _tab == 1 && !_importing && !_loading
              ? FloatingActionButton(
                  onPressed: _import,
                  tooltip: _t('import'),
                  backgroundColor: revivePurple,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            height: 70,
            backgroundColor: const Color(0xFF0D101A),
            indicatorColor: revivePurple.withValues(alpha: .24),
            selectedIndex: _tab,
            onDestinationSelected: (value) => setState(() => _tab = value),
            destinations: <Widget>[
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                label: _t('home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_rounded),
                label: _t('library'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.travel_explore),
                label: _t('archives'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                label: _t('settings'),
              ),
            ],
          ),
        ),
      );
}
