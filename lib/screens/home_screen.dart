import 'package:flutter/material.dart';
import '../services/build_archive_service.dart';

const bg = Color(0xFF080A12);
const panel = Color(0xFF141827);
const muted = Color(0xFF929AAF);
const purple = Color(0xFF9A4DFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final importer = BuildArchiveService();
  final search = TextEditingController();
  final builds = <ImportedBuild>[];
  int tab = 0;
  bool busy = false;
  String? error;

  Future<void> importBuild() async {
    setState(() { busy = true; error = null; });
    try {
      final build = await importer.pickAndImportZip();
      if (!mounted || build == null) return;
      setState(() { builds.insert(0, build); tab = 1; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Build importé dans la bibliothèque')));
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pages = [home(), library(), archives(), settings()];
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: Column(children: [header(), Expanded(child: pages[tab])])),
      bottomNavigationBar: NavigationBar(
        height: 67, backgroundColor: const Color(0xFF0D101A), indicatorColor: purple.withValues(alpha: .22),
        selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Builds'),
          NavigationDestination(icon: Icon(Icons.archive_outlined), label: 'Archives'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Réglages'),
        ],
      ),
    );
  }

  Widget header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/revive_logo.png', width: 42, height: 42, fit: BoxFit.cover)),
      const SizedBox(width: 11),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REVIVE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2)),
        Text('LAUNCHER', style: TextStyle(fontSize: 9, color: Color(0xFFBCA0F1), letterSpacing: 3, fontWeight: FontWeight.w800)),
      ]),
      const Spacer(),
      IconButton(onPressed: () => setState(() => tab = 3), icon: const CircleAvatar(radius: 17, backgroundColor: Color(0xFF33204F), child: Icon(Icons.person, size: 18, color: Color(0xFFE0CBFF))), tooltip: 'Profil'),
    ]),
  );

  Widget home() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('TON ESPACE', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5),
    const Text('Prêt à rejouer ?', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 17),
    Container(height: 235, padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23), border: Border.all(color: purple.withValues(alpha: .55)),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF35145E), Color(0xFF1A1D3C), Color(0xFF102B45)]),
      boxShadow: [BoxShadow(color: purple.withValues(alpha: .13), blurRadius: 28, offset: const Offset(0, 10))],
    ), child: Stack(children: [
      Positioned(right: -16, top: -25, child: Icon(Icons.sync_rounded, size: 205, color: Colors.white.withValues(alpha: .055))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('REVIVE  /  BUILD LIBRARY', style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: Color(0xFFDCCAFF), fontWeight: FontWeight.w900)),
        const Spacer(),
        const Text('TES ANCIENNES\nSAISONS. TON HISTOIRE.', style: TextStyle(fontSize: 23, height: 1.1, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Tous tes builds organisés au même endroit.', style: TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 15),
        FilledButton.icon(onPressed: busy ? null : importBuild, icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add, size: 18), label: Text(busy ? 'IMPORTATION…' : 'IMPORTER UN BUILD'), style: FilledButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .5))),
      ]),
    ])),
    const SizedBox(height: 25),
    section('BUILDS RÉCENTS', 'VOIR TOUT', () => setState(() => tab = 1)),
    const SizedBox(height: 11),
    if (builds.isEmpty) emptyState(compact: true) else SizedBox(height: 125, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: builds.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => recentCard(builds[i]))),
    const SizedBox(height: 24),
    section('ACCÈS RAPIDE'),
    const SizedBox(height: 10),
    Row(children: [Expanded(child: actionTile(Icons.file_upload_outlined, 'Importer un ZIP', 'Ajouter un build', importBuild)), const SizedBox(width: 10), Expanded(child: actionTile(Icons.archive_outlined, 'Archives', 'Trouver une version', () => setState(() => tab = 2)))]),
    if (error != null) errorCard(error!),
  ]);

  Widget library() {
    final q = search.text.toLowerCase().trim();
    final list = builds.where((b) => '${b.name} ${b.version}'.toLowerCase().contains(q)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
      const Text('BIBLIOTHÈQUE', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), const Text('Mes builds', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
      const SizedBox(height: 15),
      TextField(controller: search, onChanged: (_) => setState(() {}), style: const TextStyle(fontSize: 12), decoration: InputDecoration(prefixIcon: const Icon(Icons.search, color: muted), hintText: 'Rechercher un build…', filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 12))),
      const SizedBox(height: 15),
      Row(children: [Text('${list.length} BUILD${list.length == 1 ? '' : 'S'}', style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const Spacer(), TextButton.icon(onPressed: importBuild, icon: const Icon(Icons.add, size: 16), label: const Text('IMPORTER'))]),
      if (list.isEmpty) emptyState() else ...list.map(buildCard),
      if (error != null) errorCard(error!),
    ]);
  }

  Widget buildCard(ImportedBuild b) => Padding(padding: const EdgeInsets.only(bottom: 11), child: InkWell(onTap: () => showBuild(b), borderRadius: BorderRadius.circular(17), child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white10)), child: Row(children: [artwork(b.version, 91, 88), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.version, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 10)), const SizedBox(height: 8), Text('${b.sizeLabel}  •  ${b.fileCount} fichiers', style: const TextStyle(color: Color(0xFFBCA0F1), fontSize: 10, fontWeight: FontWeight.w700))])), const Icon(Icons.chevron_right, color: muted)]))));

  Widget recentCard(ImportedBuild b) => InkWell(onTap: () => showBuild(b), child: Container(width: 220, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Row(children: [artwork(b.version, 77, 105), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(b.version, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(b.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: muted))]))])));

  Widget artwork(String version, double w, double h) {
    final match = RegExp(r'^(\d+)\.').firstMatch(version);
    final season = match == null ? null : int.tryParse(match.group(1)!);
    final imageUrl = season != null && season >= 1 && season <= 41
        ? 'https://raw.githubusercontent.com/tggffoff/revive-launcher/main/atlas_link_flutter/assets/seasons/Season$season.jpg'
        : null;
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6126A8), Color(0xFF183B70), Color(0xFF101827)])),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        if (imageUrl != null) Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .02), Colors.black.withValues(alpha: .76)]))),
        Positioned(left: 8, right: 5, bottom: 8, child: Text(version, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: w < 90 ? 11 : 14, fontWeight: FontWeight.w900, shadows: const [Shadow(color: Colors.black, blurRadius: 5)]))),
      ]),
    );
  }

  Widget archives() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('ARCHIVES', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), const Text('Trouver un build', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
    const SizedBox(height: 9), const Text('Choisis une archive communautaire, télécharge ton build puis importe son ZIP dans Revive.', style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
    const SizedBox(height: 18), archiveTile('FortForge', 'Catalogue communautaire de builds', Icons.public, const Color(0xFF9C7BFF)),
    const SizedBox(height: 10), archiveTile('Carbon', 'Archive communautaire', Icons.inventory_2_outlined, const Color(0xFF42BFFF)),
    const SizedBox(height: 10), archiveTile('Helix', 'Archive communautaire', Icons.layers_outlined, const Color(0xFFE477C8)),
    const SizedBox(height: 20), actionTile(Icons.file_upload_outlined, 'ZIP déjà téléchargé ?', 'Importer dans la bibliothèque', importBuild),
  ]);

  Widget settings() => ListView(padding: const EdgeInsets.fromLTRB(18, 3, 18, 25), children: [
    const Text('PARAMÈTRES', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), const Text('Profil & préférences', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    const SizedBox(height: 17),
    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: const Row(children: [CircleAvatar(radius: 25, backgroundColor: Color(0xFF39215B), child: Icon(Icons.person, color: Color(0xFFE0CBFF))), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Compte Revive', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('Connexion Discord à intégrer', style: TextStyle(color: muted, fontSize: 10))])), Text('MODIFIER', style: TextStyle(color: Color(0xFFBDA0FF), fontSize: 9, fontWeight: FontWeight.w900))])),
    const SizedBox(height: 12), settingRow(Icons.palette_outlined, 'Apparence', 'Thème sombre Revive'), settingRow(Icons.folder_outlined, 'Bibliothèque', 'Emplacement des builds'), settingRow(Icons.info_outline, 'À propos', 'Revive Launcher Android'),
    const SizedBox(height: 14), const Text('La connexion Discord et le moteur de lancement Android seront ajoutés dans les prochaines étapes.', style: TextStyle(color: muted, fontSize: 11, height: 1.5)),
  ]);

  Widget section(String title, [String? action, VoidCallback? onTap]) => Row(children: [Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const Spacer(), if (action != null) GestureDetector(onTap: onTap, child: Text(action, style: const TextStyle(color: Color(0xFFBDA0FF), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)))]);
  Widget emptyState({bool compact = false}) => Container(padding: EdgeInsets.symmetric(vertical: compact ? 18 : 28, horizontal: 14), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(children: [Icon(Icons.inventory_2_outlined, color: muted, size: compact ? 27 : 34), const SizedBox(height: 8), const Text('Aucun build importé', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 4), const Text('Tes archives apparaîtront ici.', style: TextStyle(color: muted, fontSize: 10))]));
  Widget actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Row(children: [Container(width: 37, height: 37, decoration: BoxDecoration(color: purple.withValues(alpha: .16), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFFD1B3FF), size: 19)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: muted, fontSize: 9))]))])));
  Widget archiveTile(String title, String subtitle, IconData icon, Color color) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(icon, color: color, size: 25), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: muted, fontSize: 10))])), const Icon(Icons.chevron_right, color: muted)]));
  Widget settingRow(IconData icon, String title, String sub) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(icon, color: const Color(0xFFBDA0FF)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(sub, style: const TextStyle(color: muted, fontSize: 10))])), const Icon(Icons.chevron_right, color: muted)]));
  Widget errorCard(String e) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF3A1C29), borderRadius: BorderRadius.circular(12)), child: Text(e, style: const TextStyle(color: Color(0xFFFFB5C0), fontSize: 11)));

  void showBuild(ImportedBuild b) => showModalBottomSheet<void>(context: context, backgroundColor: panel, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(23))), builder: (ctx) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(children: [artwork(b.version, 100, 112), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.version, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(b.name, style: const TextStyle(color: muted, fontSize: 11)), const SizedBox(height: 7), Text('${b.sizeLabel} • ${b.fileCount} fichiers', style: const TextStyle(color: Color(0xFFBDA0FF), fontSize: 10))]))]), const SizedBox(height: 17), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le moteur de lancement Android reste à développer.'))); }, icon: const Icon(Icons.play_arrow), label: const Text('JOUER'), style: FilledButton.styleFrom(backgroundColor: purple, padding: const EdgeInsets.symmetric(vertical: 14)))), const SizedBox(height: 7), const Text('Le bouton est présent ; le lancement du build n’est pas encore implémenté.', style: TextStyle(color: muted, fontSize: 10))])));
}
