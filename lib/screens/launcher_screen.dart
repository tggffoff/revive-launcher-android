import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/imported_build.dart';
import '../services/build_archive_service.dart';

const _purple = Color(0xFF9A4DFF);
const _panel = Color(0xFF151827);
const _muted = Color(0xFF929AAF);

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key, required this.user});
  final User user;

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  final _archive = BuildArchiveService();
  final _search = TextEditingController();
  final _builds = <ImportedBuild>[];
  int _tab = 0;
  bool _loading = true;
  bool _busy = false;
  String _language = 'auto';
  String? _nickname;

  String get _lang {
    if (_language != 'auto') return _language;
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return ['fr', 'es'].contains(device) ? device : 'en';
  }

  static const _words = <String, Map<String, String>>{
    'fr': {'home':'Accueil','library':'Bibliothèque','archives':'Archives','settings':'Paramètres','welcome':'Prêt à rejouer ?','tagline':'TES ANCIENNES SAISONS. TON HISTOIRE.','hero':'Tous tes builds Android au même endroit.','import':'IMPORTER UN BUILD ZIP','recent':'BUILDS RÉCENTS','view':'VOIR TOUT','empty':'Aucun build importé','emptyHint':'Importe une archive ZIP pour commencer.','myBuilds':'Mes builds','search':'Rechercher un build…','profile':'Profil Discord','language':'Langue','auto':'Automatique (langue du téléphone)','fr':'Français','en':'English','es':'Español','signOut':'Se déconnecter','edit':'Modifier','save':'Enregistrer','cancel':'Annuler','play':'LANCER','playInfo':'Le lancement des builds Fortnite Android n’est pas encore implémenté.','fortforge':'OUVRIR FORTFORGE','archivesHint':'Ouvre FortForge pour trouver un build Android, télécharge son ZIP puis importe-le ici.','name':'Nom du build','version':'Version','description':'Description','trailer':'Lien du trailer YouTube','trailerSearch':'Rechercher le trailer sur YouTube','files':'fichiers','delete':'Supprimer','imported':'Build ajouté à la bibliothèque.','login':'Compte Discord','nickname':'Pseudo affiché'},
    'en': {'home':'Home','library':'Library','archives':'Archives','settings':'Settings','welcome':'Ready to play again?','tagline':'YOUR OLD SEASONS. YOUR STORY.','hero':'All your Android builds in one place.','import':'IMPORT BUILD ZIP','recent':'RECENT BUILDS','view':'VIEW ALL','empty':'No builds imported','emptyHint':'Import a ZIP archive to get started.','myBuilds':'My builds','search':'Search builds…','profile':'Discord profile','language':'Language','auto':'Automatic (device language)','fr':'Français','en':'English','es':'Español','signOut':'Sign out','edit':'Edit','save':'Save','cancel':'Cancel','play':'LAUNCH','playInfo':'Launching Fortnite Android builds is not implemented yet.','fortforge':'OPEN FORTFORGE','archivesHint':'Open FortForge to find an Android build, download its ZIP and import it here.','name':'Build name','version':'Version','description':'Description','trailer':'YouTube trailer link','trailerSearch':'Search for trailer on YouTube','files':'files','delete':'Delete','imported':'Build added to library.','login':'Discord account','nickname':'Display nickname'},
    'es': {'home':'Inicio','library':'Biblioteca','archives':'Archivos','settings':'Ajustes','welcome':'¿Listo para volver?','tagline':'TUS TEMPORADAS ANTIGUAS. TU HISTORIA.','hero':'Todos tus builds Android en un solo lugar.','import':'IMPORTAR BUILD ZIP','recent':'BUILDS RECIENTES','view':'VER TODO','empty':'No hay builds importados','emptyHint':'Importa un archivo ZIP para empezar.','myBuilds':'Mis builds','search':'Buscar build…','profile':'Perfil de Discord','language':'Idioma','auto':'Automático (idioma del dispositivo)','fr':'Français','en':'English','es':'Español','signOut':'Cerrar sesión','edit':'Editar','save':'Guardar','cancel':'Cancelar','play':'INICIAR','playInfo':'El inicio de builds Fortnite Android aún no está implementado.','fortforge':'ABRIR FORTFORGE','archivesHint':'Abre FortForge, descarga el ZIP de un build Android e impórtalo aquí.','name':'Nombre del build','version':'Versión','description':'Descripción','trailer':'Enlace del tráiler de YouTube','trailerSearch':'Buscar tráiler en YouTube','files':'archivos','delete':'Eliminar','imported':'Build añadido a la biblioteca.','login':'Cuenta Discord','nickname':'Apodo visible'},
  };

  String t(String key) => _words[_lang]?[key] ?? _words['en']![key]!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('revive_builds');
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _builds.addAll(list.map(ImportedBuild.fromJson));
      } catch (_) {
        await prefs.remove('revive_builds');
      }
    }
    if (!mounted) return;
    setState(() {
      _language = prefs.getString('revive_language') ?? 'auto';
      _nickname = prefs.getString('revive_nickname');
      _loading = false;
    });
  }

  Future<void> _saveBuilds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('revive_builds', jsonEncode(_builds.map((b) => b.toJson()).toList()));
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final build = await _archive.pickAndImportZip();
      if (build == null || !mounted) return;
      setState(() { _builds.insert(0, build); _tab = 1; });
      await _saveBuilds();
      if (mounted) _toast(t('imported'));
      if (mounted) await _editBuild(build);
    } catch (error) {
      if (mounted) _toast(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editBuild(ImportedBuild build) async {
    final name = TextEditingController(text: build.name);
    final version = TextEditingController(text: build.version);
    final description = TextEditingController(text: build.description);
    final trailer = TextEditingController(text: build.trailerUrl);
    final result = await showDialog<ImportedBuild>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('edit')),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(name, t('name')),
          _dialogField(version, t('version')),
          _dialogField(description, t('description'), maxLines: 3),
          _dialogField(trailer, t('trailer')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, build.copyWith(name: name.text.trim(), version: version.text.trim(), description: description.text.trim(), trailerUrl: trailer.text.trim())), child: Text(t('save'))),
        ],
      ),
    );
    name.dispose(); version.dispose(); description.dispose(); trailer.dispose();
    if (result == null || !mounted) return;
    final index = _builds.indexWhere((b) => b.id == build.id);
    if (index >= 0) setState(() => _builds[index] = result);
    await _saveBuilds();
  }

  Widget _dialogField(TextEditingController controller, String label, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );

  Future<void> _settings() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = TextEditingController(text: _nickname ?? _discordName);
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(t('nickname')),
      content: TextField(controller: nickname, maxLength: 32),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, nickname.text.trim()), child: Text(t('save'))),
      ],
    ));
    nickname.dispose();
    if (result != null) {
      await prefs.setString('revive_nickname', result);
      if (mounted) setState(() => _nickname = result);
    }
  }

  String get _discordName {
    final meta = widget.user.userMetadata ?? {};
    return (meta['global_name'] ?? meta['full_name'] ?? meta['name'] ?? widget.user.email ?? 'Discord user').toString();
  }

  String? get _avatarUrl {
    final meta = widget.user.userMetadata ?? {};
    final value = meta['avatar_url'] ?? meta['picture'];
    return value is String && value.startsWith('https://') ? value : null;
  }

  Future<void> _signOut() async => Supabase.instance.client.auth.signOut();

  Future<void> _setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('revive_language', value);
    if (mounted) setState(() => _language = value);
  }

  Future<void> _delete(ImportedBuild build) async {
    await _archive.deleteBuild(build);
    if (!mounted) return;
    setState(() => _builds.removeWhere((b) => b.id == build.id));
    await _saveBuilds();
    if (mounted) Navigator.pop(context);
  }

  void _toast(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _library(), _archives(), _settingsPage()];
    return Scaffold(
      body: SafeArea(child: Column(children: [_header(), Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : pages[_tab])])),
      bottomNavigationBar: NavigationBar(
        height: 68, backgroundColor: const Color(0xFF0D101A), indicatorColor: _purple.withValues(alpha: .22),
        selectedIndex: _tab, onDestinationSelected: (v) => setState(() => _tab = v),
        destinations: [NavigationDestination(icon: const Icon(Icons.home_outlined), label: t('home')), NavigationDestination(icon: const Icon(Icons.grid_view_rounded), label: t('library')), NavigationDestination(icon: const Icon(Icons.archive_outlined), label: t('archives')), NavigationDestination(icon: const Icon(Icons.settings_outlined), label: t('settings'))],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/revive_logo.png', width: 42, height: 42, fit: BoxFit.cover)),
      const SizedBox(width: 11),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('REVIVE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2)), Text('LAUNCHER', style: TextStyle(fontSize: 9, color: Color(0xFFBCA0F1), letterSpacing: 3, fontWeight: FontWeight.w800))]),
      const Spacer(),
      GestureDetector(onTap: () => setState(() => _tab = 3), child: _avatar(36)),
    ]),
  );

  Widget _avatar(double size) => CircleAvatar(
    radius: size / 2,
    backgroundColor: const Color(0xFF39215B),
    backgroundImage: _avatarUrl == null ? null : NetworkImage(_avatarUrl!),
    child: _avatarUrl == null ? Icon(Icons.person, color: const Color(0xFFE0CBFF), size: size * .55) : null,
  );

  Widget _home() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('REVIVE / ANDROID', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), Text(t('welcome'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 17),
    Container(height: 235, padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23), border: Border.all(color: _purple.withValues(alpha: .55)),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF35145E), Color(0xFF1A1D3C), Color(0xFF102B45)]),
    ), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('tagline'), style: const TextStyle(fontSize: 21, height: 1.1, fontWeight: FontWeight.w900)),
      const Spacer(), Text(t('hero'), style: const TextStyle(fontSize: 11, color: Colors.white70)), const SizedBox(height: 15),
      FilledButton.icon(onPressed: _busy ? null : _import, icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add), label: Text(t('import')), style: FilledButton.styleFrom(backgroundColor: _purple)),
    ])),
    const SizedBox(height: 25),
    Row(children: [Text(t('recent'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const Spacer(), TextButton(onPressed: () => setState(() => _tab = 1), child: Text(t('view')))]),
    if (_builds.isEmpty) _empty(compact: true) else SizedBox(height: 132, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _builds.length.clamp(0, 8), separatorBuilder: (_, index) => const SizedBox(width: 10), itemBuilder: (_, index) => _recentCard(_builds[index]))),
  ]);

  Widget _library() {
    final q = _search.text.toLowerCase().trim();
    final list = _builds.where((b) => '${b.name} ${b.version}'.toLowerCase().contains(q)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
      const Text('REVIVE / LIBRARY', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), Text(t('myBuilds'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
      const SizedBox(height: 15), TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t('search'), filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none))),
      const SizedBox(height: 12),
      Row(children: [Text('${list.length} BUILDS', style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w900)), const Spacer(), TextButton.icon(onPressed: _import, icon: const Icon(Icons.add), label: Text(t('import')))]),
      if (list.isEmpty) _empty() else ...list.map(_buildCard),
    ]);
  }

  Widget _archives() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('REVIVE / ARCHIVES', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), Text(t('archives'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 9), Text(t('archivesHint'), style: const TextStyle(color: _muted, fontSize: 12, height: 1.5)),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white10)), child: Row(children: [
      const Icon(Icons.cloud_download_outlined, color: Color(0xFFD1B3FF), size: 34), const SizedBox(width: 13),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FortForge', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), SizedBox(height: 4), Text('Catalogue communautaire de builds', style: TextStyle(color: _muted, fontSize: 10)), SizedBox(height: 4), Text('fortforge.co.uk', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10))])),
      const Icon(Icons.open_in_new, color: _muted),
    ])),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _openUrl('https://fortforge.co.uk'), icon: const Icon(Icons.open_in_new), label: Text(t('fortforge')), style: FilledButton.styleFrom(backgroundColor: _purple, padding: const EdgeInsets.symmetric(vertical: 14)))),
    const SizedBox(height: 10),
    OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.file_upload_outlined), label: Text(t('import'))),
  ]);

  Widget _settingsPage() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('REVIVE / SETTINGS', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), Text(t('settings'), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 17),
    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Row(children: [
      _avatar(52), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_nickname?.isNotEmpty == true ? _nickname! : _discordName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(widget.user.email ?? 'Discord', style: const TextStyle(color: _muted, fontSize: 10))])),
      TextButton(onPressed: _settings, child: Text(t('edit'))),
    ])),
    const SizedBox(height: 10), OutlinedButton.icon(onPressed: _signOut, icon: const Icon(Icons.logout), label: Text(t('signOut'))),
    const SizedBox(height: 20), Text(t('language'), style: const TextStyle(fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Container(padding: const EdgeInsets.symmetric(horizontal: 13), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: _language, isExpanded: true,
      items: [DropdownMenuItem(value: 'auto', child: Text(t('auto'))), DropdownMenuItem(value: 'fr', child: Text(t('fr'))), DropdownMenuItem(value: 'en', child: Text(t('en'))), DropdownMenuItem(value: 'es', child: Text(t('es')))],
      onChanged: (value) { if (value != null) _setLanguage(value); },
    ))),
    const SizedBox(height: 18), const Text('REVIVE LAUNCHER ANDROID • 1.0.0', style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.2)),
    const SizedBox(height: 5), const Text('Le bouton LANCER est un emplacement d’interface : Android ne peut pas exécuter automatiquement un build Fortnite arbitraire importé comme ZIP.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
  ]);

  Widget _empty({bool compact = false}) => Container(padding: EdgeInsets.symmetric(vertical: compact ? 18 : 28, horizontal: 14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(children: [Icon(Icons.inventory_2_outlined, color: _muted, size: compact ? 27 : 34), const SizedBox(height: 8), Text(t('empty'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), Text(t('emptyHint'), style: const TextStyle(color: _muted, fontSize: 10))]));

  Widget _artwork(String version, double width, double height) => Container(
    width: width, height: height, clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6126A8), Color(0xFF183B70), Color(0xFF101827)])),
    child: Stack(fit: StackFit.expand, children: [
      const Center(child: Icon(Icons.sports_esports_outlined, size: 43, color: Color(0x44FFFFFF))),
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .72)]))),
      Positioned(left: 8, right: 5, bottom: 8, child: Text(version, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))),
    ]),
  );

  Widget _buildCard(ImportedBuild b) => Padding(padding: const EdgeInsets.only(bottom: 11), child: InkWell(onTap: () => _showBuild(b), borderRadius: BorderRadius.circular(17), child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white10)), child: Row(children: [
    _artwork(b.version, 91, 88), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.version, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10)), const SizedBox(height: 8), Text('${b.sizeLabel} • ${b.fileCount} ${t('files')}', style: const TextStyle(color: Color(0xFFBCA0F1), fontSize: 10, fontWeight: FontWeight.w700))])),
    const Icon(Icons.chevron_right, color: _muted),
  ]))));

  Widget _recentCard(ImportedBuild b) => InkWell(onTap: () => _showBuild(b), child: Container(width: 220, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Row(children: [_artwork(b.version, 77, 105), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(b.version, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(b.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted))]))])));

  void _showBuild(ImportedBuild b) => showModalBottomSheet<void>(
    context: context, backgroundColor: _panel, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(23))),
    builder: (ctx) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [_artwork(b.version, 100, 112), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.version, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(b.name, style: const TextStyle(color: _muted, fontSize: 11)), const SizedBox(height: 7), Text('${b.sizeLabel} • ${b.fileCount} ${t('files')}', style: const TextStyle(color: Color(0xFFBDA0FF), fontSize: 10))]))]),
      const SizedBox(height: 12), Text(b.description, style: const TextStyle(color: _muted, fontSize: 12, height: 1.4)),
      if (b.hasEngine || b.hasFortniteGame) ...[const SizedBox(height: 8), Text('Structure : ${b.hasEngine ? 'Engine ' : ''}${b.hasFortniteGame ? 'FortniteGame' : ''}', style: const TextStyle(color: Colors.greenAccent, fontSize: 10))],
      const SizedBox(height: 15),
      if (b.trailerUrl.isNotEmpty) SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _openUrl(b.trailerUrl), icon: const Icon(Icons.ondemand_video), label: const Text('YOUTUBE TRAILER'))),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { Navigator.pop(ctx); _toast(t('playInfo')); }, icon: const Icon(Icons.play_arrow), label: Text(t('play')), style: FilledButton.styleFrom(backgroundColor: _purple, padding: const EdgeInsets.symmetric(vertical: 14)))),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(onPressed: () { Navigator.pop(ctx); _editBuild(b); }, icon: const Icon(Icons.edit_outlined), label: Text(t('edit'))), TextButton.icon(onPressed: () => _delete(b), icon: const Icon(Icons.delete_outline), label: Text(t('delete')))]),
    ])),
  );

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !['https', 'http'].contains(uri.scheme)) {
      _toast('Lien invalide.');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) _toast('Impossible d’ouvrir ce lien.');
  }
}
