import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/build_archive_service.dart';

const _bg = Color(0xFF080A12);
const _panel = Color(0xFF141827);
const _muted = Color(0xFF929AAF);
const _purple = Color(0xFF9A4DFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.supabaseConfigured});
  final bool supabaseConfigured;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _archive = BuildArchiveService();
  final _search = TextEditingController();
  final _auth = ReviveAuthService();
  final _builds = <ImportedBuild>[];
  StreamSubscription<AuthState>? _authSubscription;

  int _tab = 0;
  bool _busy = false;
  bool _loading = true;
  String _language = 'en';
  String? _nickname;
  String? _error;

  static const _translations = <String, Map<String, String>>{
    'fr': {
      'home': 'Accueil', 'library': 'Bibliothèque', 'archives': 'Archives', 'settings': 'Paramètres',
      'welcome': 'Prêt à rejouer ?', 'tagline': 'TES ANCIENNES SAISONS. TON HISTOIRE.',
      'hero': 'Tous tes builds Android organisés au même endroit.',
      'import': 'IMPORTER UN BUILD ZIP', 'recent': 'BUILDS RÉCENTS', 'all': 'VOIR TOUT',
      'empty': 'Aucun build importé', 'emptyHint': 'Tes archives apparaîtront ici.',
      'search': 'Rechercher un build…', 'myBuilds': 'Mes builds', 'profile': 'Profil Discord',
      'connect': 'SE CONNECTER AVEC DISCORD', 'disconnect': 'Se déconnecter',
      'language': 'Langue', 'automatic': 'Automatique (langue du téléphone)',
      'french': 'Français', 'english': 'English', 'spanish': 'Español',
      'accountHint': 'Connecte ton compte Discord pour retrouver ton profil.',
      'archivesHint': 'Parcours les builds Android disponibles sur FortForge, puis importe le ZIP téléchargé.',
      'openFortForge': 'OUVRIR FORTFORGE', 'play': 'JOUER', 'playHint': 'Le lancement Android n’est pas encore activé.',
      'version': 'Version', 'files': 'fichiers', 'delete': 'Supprimer', 'cancel': 'Annuler',
      'name': 'Pseudo affiché', 'save': 'Enregistrer', 'loginRequired': 'Configure Supabase pour activer la connexion Discord.',
      'imported': 'Build importé dans la bibliothèque', 'badZip': 'Impossible d’importer ce fichier ZIP.',
      'logout': 'Déconnexion effectuée', 'engine': 'Dossier Engine détecté', 'game': 'Dossier FortniteGame détecté',
    },
    'en': {
      'home': 'Home', 'library': 'Library', 'archives': 'Archives', 'settings': 'Settings',
      'welcome': 'Ready to play again?', 'tagline': 'YOUR OLD SEASONS. YOUR STORY.',
      'hero': 'All your Android builds, organized in one place.',
      'import': 'IMPORT BUILD ZIP', 'recent': 'RECENT BUILDS', 'all': 'VIEW ALL',
      'empty': 'No imported builds', 'emptyHint': 'Your archives will appear here.',
      'search': 'Search builds…', 'myBuilds': 'My builds', 'profile': 'Discord profile',
      'connect': 'SIGN IN WITH DISCORD', 'disconnect': 'Sign out',
      'language': 'Language', 'automatic': 'Automatic (device language)',
      'french': 'Français', 'english': 'English', 'spanish': 'Español',
      'accountHint': 'Connect your Discord account to show your profile.',
      'archivesHint': 'Browse Android builds on FortForge, then import the ZIP you downloaded.',
      'openFortForge': 'OPEN FORTFORGE', 'play': 'PLAY', 'playHint': 'Android build launching is not enabled yet.',
      'version': 'Version', 'files': 'files', 'delete': 'Delete', 'cancel': 'Cancel',
      'name': 'Display nickname', 'save': 'Save', 'loginRequired': 'Configure Supabase to enable Discord sign-in.',
      'imported': 'Build imported into your library', 'badZip': 'Could not import this ZIP file.',
      'logout': 'Signed out', 'engine': 'Engine folder detected', 'game': 'FortniteGame folder detected',
    },
    'es': {
      'home': 'Inicio', 'library': 'Biblioteca', 'archives': 'Archivos', 'settings': 'Ajustes',
      'welcome': '¿Listo para volver?', 'tagline': 'TUS TEMPORADAS ANTIGUAS. TU HISTORIA.',
      'hero': 'Todos tus builds Android organizados en un solo lugar.',
      'import': 'IMPORTAR BUILD ZIP', 'recent': 'BUILDS RECIENTES', 'all': 'VER TODO',
      'empty': 'No hay builds importados', 'emptyHint': 'Tus archivos aparecerán aquí.',
      'search': 'Buscar un build…', 'myBuilds': 'Mis builds', 'profile': 'Perfil de Discord',
      'connect': 'INICIAR SESIÓN CON DISCORD', 'disconnect': 'Cerrar sesión',
      'language': 'Idioma', 'automatic': 'Automático (idioma del dispositivo)',
      'french': 'Français', 'english': 'English', 'spanish': 'Español',
      'accountHint': 'Conecta tu cuenta de Discord para mostrar tu perfil.',
      'archivesHint': 'Explora los builds Android en FortForge e importa el ZIP descargado.',
      'openFortForge': 'ABRIR FORTFORGE', 'play': 'JUGAR', 'playHint': 'El inicio de builds Android aún no está activado.',
      'version': 'Versión', 'files': 'archivos', 'delete': 'Eliminar', 'cancel': 'Cancelar',
      'name': 'Apodo visible', 'save': 'Guardar', 'loginRequired': 'Configura Supabase para activar Discord.',
      'imported': 'Build importado a la biblioteca', 'badZip': 'No se pudo importar este archivo ZIP.',
      'logout': 'Sesión cerrada', 'engine': 'Carpeta Engine detectada', 'game': 'Carpeta FortniteGame detectada',
    },
  };

  String tr(String key) => _translations[_language]?[key] ?? _translations['en']![key]!;

  @override
  void initState() {
    super.initState();
    _loadLocalState();
    if (widget.supabaseConfigured) {
      _authSubscription = _auth.onAuthStateChange.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final savedLanguage = prefs.getString('language') ?? 'auto';
    final resolved = savedLanguage == 'auto'
        ? (['fr', 'es'].contains(deviceLanguage) ? deviceLanguage : 'en')
        : savedLanguage;
    final nickname = prefs.getString('profile_nickname');
    final stored = prefs.getString('imported_builds');
    if (stored != null) {
      try {
        final values = (jsonDecode(stored) as List).cast<Map<String, dynamic>>();
        _builds.addAll(values.map(ImportedBuild.fromJson));
      } catch (_) {
        await prefs.remove('imported_builds');
      }
    }
    if (mounted) {
      setState(() {
        _language = resolved;
        _nickname = nickname;
        _loading = false;
      });
    }
  }

  Future<void> _saveBuilds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('imported_builds', jsonEncode(_builds.map((b) => b.toJson()).toList()));
  }

  Future<void> _setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    final deviceLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    setState(() => _language = value == 'auto'
        ? (['fr', 'es'].contains(deviceLanguage) ? deviceLanguage : 'en')
        : value);
  }

  Future<void> _importBuild() async {
    setState(() { _busy = true; _error = null; });
    try {
      final build = await _archive.pickAndImportZip();
      if (!mounted || build == null) return;
      setState(() { _builds.insert(0, build); _tab = 1; });
      await _saveBuilds();
      if (mounted) _message(tr('imported'));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    if (!widget.supabaseConfigured) {
      _message(tr('loginRequired'));
      return;
    }
    try {
      await _auth.signInWithDiscord();
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) _message(tr('logout'));
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _nickname ?? _discordName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('name')),
        content: TextField(controller: controller, maxLength: 32, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(tr('save'))),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_nickname', value);
    if (mounted) setState(() => _nickname = value.isEmpty ? null : value);
  }

  String get _discordName {
    if (!widget.supabaseConfigured) return 'Revive user';
    final metadata = _auth.currentUser?.userMetadata ?? {};
    return (metadata['global_name'] ?? metadata['full_name'] ?? metadata['name'] ?? 'Discord user').toString();
  }

  String? get _avatarUrl {
    if (!widget.supabaseConfigured) return null;
    final metadata = _auth.currentUser?.userMetadata ?? {};
    final value = metadata['avatar_url'] ?? metadata['picture'];
    return value is String && value.startsWith('https://') ? value : null;
  }

  bool get _signedIn => widget.supabaseConfigured && _auth.currentUser != null;

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _library(), _archives(), _settings()];
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: Column(children: [_header(), Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : pages[_tab])])),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: const Color(0xFF0D101A),
        indicatorColor: _purple.withValues(alpha: .22),
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: tr('home')),
          NavigationDestination(icon: const Icon(Icons.grid_view_rounded), label: tr('library')),
          NavigationDestination(icon: const Icon(Icons.archive_outlined), label: tr('archives')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: tr('settings')),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/revive_logo.png', width: 42, height: 42, fit: BoxFit.cover)),
      const SizedBox(width: 11),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REVIVE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2)),
        Text('LAUNCHER', style: TextStyle(fontSize: 9, color: Color(0xFFBCA0F1), letterSpacing: 3, fontWeight: FontWeight.w800)),
      ]),
      const Spacer(),
      IconButton(onPressed: () => setState(() => _tab = 3), icon: _avatar(size: 34), tooltip: tr('profile')),
    ]),
  );

  Widget _avatar({double size = 48}) => CircleAvatar(
    radius: size / 2,
    backgroundColor: const Color(0xFF39215B),
    backgroundImage: _avatarUrl == null ? null : NetworkImage(_avatarUrl!),
    child: _avatarUrl == null ? Icon(Icons.person, color: const Color(0xFFE0CBFF), size: size * .55) : null,
  );

  Widget _home() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('REVIVE / ANDROID', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5),
    Text(tr('welcome'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 17),
    Container(height: 235, padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23), border: Border.all(color: _purple.withValues(alpha: .55)),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF35145E), Color(0xFF1A1D3C), Color(0xFF102B45)]),
      boxShadow: [BoxShadow(color: _purple.withValues(alpha: .13), blurRadius: 28, offset: const Offset(0, 10))],
    ), child: Stack(children: [
      Positioned(right: -16, top: -25, child: Icon(Icons.sync_rounded, size: 205, color: Colors.white.withValues(alpha: .055))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('tagline'), style: const TextStyle(fontSize: 21, height: 1.1, fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(tr('hero'), style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 15),
        FilledButton.icon(onPressed: _busy ? null : _importBuild, icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add, size: 18), label: Text(tr('import')), style: FilledButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .5))),
      ]),
    ])),
    const SizedBox(height: 25),
    _section(tr('recent'), tr('all'), () => setState(() => _tab = 1)),
    const SizedBox(height: 11),
    if (_builds.isEmpty) _empty(compact: true) else SizedBox(height: 125, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _builds.length.clamp(0, 8), separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => _recentCard(_builds[i]))),
    if (_error != null) _errorCard(_error!),
  ]);

  Widget _library() {
    final query = _search.text.toLowerCase().trim();
    final list = _builds.where((b) => '${b.name} ${b.version}'.toLowerCase().contains(query)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
      const Text('REVIVE / LIBRARY', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(tr('myBuilds'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
      const SizedBox(height: 15),
      TextField(controller: _search, onChanged: (_) => setState(() {}), style: const TextStyle(fontSize: 12), decoration: InputDecoration(prefixIcon: const Icon(Icons.search, color: _muted), hintText: tr('search'), filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none))),
      const SizedBox(height: 12),
      Row(children: [Text('${list.length} BUILDS', style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const Spacer(), TextButton.icon(onPressed: _importBuild, icon: const Icon(Icons.add, size: 16), label: Text(tr('import')))]),
      if (list.isEmpty) _empty() else ...list.map(_buildCard),
      if (_error != null) _errorCard(_error!),
    ]);
  }

  Widget _archives() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('REVIVE / ARCHIVES', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), Text(tr('archives'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 9), Text(tr('archivesHint'), style: const TextStyle(color: _muted, fontSize: 12, height: 1.5)),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white10)), child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: _purple.withValues(alpha: .18), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.cloud_download_outlined, color: Color(0xFFD1B3FF), size: 26)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FortForge', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        SizedBox(height: 4), Text('Catalogue des builds Fortnite Android', style: TextStyle(color: _muted, fontSize: 10)),
        SizedBox(height: 4), Text('fortforge.co.uk/builds/android', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10)),
      ])),
    ])),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => launchUrl(Uri.parse('https://fortforge.co.uk/builds/android'), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: Text(tr('openFortForge')), style: FilledButton.styleFrom(backgroundColor: _purple, padding: const EdgeInsets.symmetric(vertical: 14)))),
    const SizedBox(height: 10),
    OutlinedButton.icon(onPressed: _importBuild, icon: const Icon(Icons.file_upload_outlined), label: Text(tr('import'))),
  ]);

  Widget _settings() {
    final user = _auth.currentUser;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
      const Text('REVIVE / SETTINGS', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(tr('settings'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
      const SizedBox(height: 17),
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Row(children: [
        _avatar(size: 52), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_nickname ?? _discordName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4), Text(user?.email ?? tr('accountHint'), maxLines: 2, style: const TextStyle(color: _muted, fontSize: 10)),
        ])),
        if (_signedIn) IconButton(onPressed: _editNickname, icon: const Icon(Icons.edit_outlined, color: Color(0xFFBDA0FF))),
      ])),
      const SizedBox(height: 10),
      if (!_signedIn) SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _signIn, icon: const Icon(Icons.discord), label: Text(tr('connect')), style: FilledButton.styleFrom(backgroundColor: _purple, padding: const EdgeInsets.symmetric(vertical: 14))))
      else OutlinedButton.icon(onPressed: _signOut, icon: const Icon(Icons.logout), label: Text(tr('disconnect'))),
      const SizedBox(height: 20),
      Text(tr('language'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 13), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _language,
        isExpanded: true,
        items: [
          DropdownMenuItem(value: 'auto', child: Text(tr('automatic'))),
          DropdownMenuItem(value: 'fr', child: Text(tr('french'))),
          DropdownMenuItem(value: 'en', child: Text(tr('english'))),
          DropdownMenuItem(value: 'es', child: Text(tr('spanish'))),
        ],
        onChanged: (value) { if (value != null) _setLanguage(value); },
      ))),
      const SizedBox(height: 18),
      const Text('REVIVE LAUNCHER ANDROID', style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('Discord OAuth via Supabase. Les builds ZIP sont stockés dans l’espace privé de l’application. Le bouton JOUER reste un emplacement en attendant un moteur Android compatible.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
    ]);
  }

  Widget _section(String title, String action, VoidCallback onTap) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
    const Spacer(), GestureDetector(onTap: onTap, child: Text(action, style: const TextStyle(color: Color(0xFFBDA0FF), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1))),
  ]);

  Widget _empty({bool compact = false}) => Container(padding: EdgeInsets.symmetric(vertical: compact ? 18 : 28, horizontal: 14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(children: [
    Icon(Icons.inventory_2_outlined, color: _muted, size: compact ? 27 : 34), const SizedBox(height: 8),
    Text(tr('empty'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    Text(tr('emptyHint'), style: const TextStyle(color: _muted, fontSize: 10)),
  ]));

  Widget _artwork(String version, double width, double height) => Container(
    width: width, height: height,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6126A8), Color(0xFF183B70), Color(0xFF101827)])),
    clipBehavior: Clip.antiAlias,
    child: Stack(fit: StackFit.expand, children: [
      Center(child: Icon(Icons.sports_esports_outlined, size: width * .42, color: Colors.white.withValues(alpha: .22))),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .7)]))),
      Positioned(left: 8, right: 5, bottom: 8, child: Text(version, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: width < 90 ? 11 : 14, fontWeight: FontWeight.w900))),
    ]),
  );

  Widget _buildCard(ImportedBuild build) => Padding(padding: const EdgeInsets.only(bottom: 11), child: InkWell(onTap: () => _showBuild(build), borderRadius: BorderRadius.circular(17), child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white10)), child: Row(children: [
    _artwork(build.version, 91, 88), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(build.version, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(build.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)),
      const SizedBox(height: 8), Text('${build.sizeLabel} • ${build.fileCount} ${tr('files')}', style: const TextStyle(color: Color(0xFFBCA0F1), fontSize: 10, fontWeight: FontWeight.w700)),
    ])),
    const Icon(Icons.chevron_right, color: _muted),
  ]))));

  Widget _recentCard(ImportedBuild build) => InkWell(onTap: () => _showBuild(build), child: Container(width: 220, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Row(children: [
    _artwork(build.version, 77, 105), const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(build.version, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(build.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
    ])),
  ])));

  Widget _errorCard(String error) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF3A1C29), borderRadius: BorderRadius.circular(12)), child: Text(error, style: const TextStyle(color: Color(0xFFFFB5C0), fontSize: 11)));

  Future<void> _removeBuild(ImportedBuild build) async {
    await _archive.deleteBuild(build);
    if (!mounted) return;
    setState(() => _builds.remove(build));
    await _saveBuilds();
    if (mounted) Navigator.pop(context);
  }

  void _showBuild(ImportedBuild build) => showModalBottomSheet<void>(
    context: context, backgroundColor: _panel, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(23))),
    builder: (sheetContext) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [_artwork(build.version, 100, 112), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(build.version, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5), Text(build.name, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 7), Text('${build.sizeLabel} • ${build.fileCount} ${tr('files')}', style: const TextStyle(color: Color(0xFFBDA0FF), fontSize: 10)),
      ]))]),
      const SizedBox(height: 12),
      if (build.hasEngine) Text('✓ ${tr('engine')}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
      if (build.hasFortniteGame) Text('✓ ${tr('game')}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
      const SizedBox(height: 15),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { Navigator.pop(sheetContext); _message(tr('playHint')); }, icon: const Icon(Icons.play_arrow), label: Text(tr('play')), style: FilledButton.styleFrom(backgroundColor: _purple, padding: const EdgeInsets.symmetric(vertical: 14)))),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _removeBuild(build), icon: const Icon(Icons.delete_outline), label: Text(tr('delete')))),
    ])),
  );
}
