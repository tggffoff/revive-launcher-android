/// All user-facing texts. Each entry is ordered: French, English, Spanish.
library;

const supportedLanguages = <String>['fr', 'en', 'es'];

/// Manual choice first, then the phone language, then English.
String resolveLanguage(String preference, String deviceLanguage) {
  if (supportedLanguages.contains(preference)) return preference;
  if (supportedLanguages.contains(deviceLanguage)) return deviceLanguage;
  return 'en';
}

String translate(
  String language,
  String key, [
  Map<String, Object> args = const <String, Object>{},
]) {
  final values = translations[key];
  if (values == null) return key;
  final index = supportedLanguages.indexOf(language);
  var text = values[index < 0 ? 1 : index];
  for (final entry in args.entries) {
    text = text.replaceAll('{${entry.key}}', '${entry.value}');
  }
  return text;
}

const translations = <String, List<String>>{
  'home': ['Accueil', 'Home', 'Inicio'],
  'library': ['Bibliothèque', 'Library', 'Biblioteca'],
  'archives': ['Catalogue', 'Catalog', 'Catálogo'],
  'settings': ['Paramètres', 'Settings', 'Ajustes'],
  'welcome': ['Prêt à rejouer ?', 'Ready to play again?', '¿Listo para volver?'],
  'tagline': [
    'TES ANCIENNES SAISONS. TON HISTOIRE.',
    'YOUR OLD SEASONS. YOUR STORY.',
    'TUS TEMPORADAS ANTIGUAS. TU HISTORIA.',
  ],
  'hero': [
    'Tous tes builds Android au même endroit.',
    'All your Android builds in one place.',
    'Todos tus builds de Android en un solo lugar.',
  ],
  'signIn': [
    'SE CONNECTER AVEC DISCORD',
    'SIGN IN WITH DISCORD',
    'INICIAR SESIÓN CON DISCORD',
  ],
  'signInHint': [
    'La page Discord s’ouvre dans ton navigateur, puis tu reviens ici.',
    'Discord opens in your browser, then you come back here.',
    'Discord se abre en el navegador y después vuelves aquí.',
  ],
  'authNotConfigured': [
    'La connexion Discord n’est pas configurée.',
    'Discord sign-in is not configured.',
    'El inicio de sesión con Discord no está configurado.',
  ],
  'signInFailed': [
    'Connexion Discord impossible : {error}',
    'Discord sign-in failed: {error}',
    'No se pudo iniciar sesión con Discord: {error}',
  ],
  'browserFailed': [
    'Impossible d’ouvrir le navigateur.',
    'Could not open the browser.',
    'No se pudo abrir el navegador.',
  ],
  'import': ['IMPORTER UN ZIP', 'IMPORT A ZIP', 'IMPORTAR UN ZIP'],
  'recent': ['BUILDS RÉCENTS', 'RECENT BUILDS', 'BUILDS RECIENTES'],
  'view': ['VOIR TOUT', 'VIEW ALL', 'VER TODO'],
  'empty': ['Aucun build importé', 'No builds imported', 'No hay builds importados'],
  'emptyHint': [
    'Importe une archive ZIP pour commencer.',
    'Import a ZIP archive to get started.',
    'Importa un archivo ZIP para empezar.',
  ],
  'noResult': ['Aucun résultat', 'No results', 'Sin resultados'],
  'myBuilds': ['Mes builds', 'My builds', 'Mis builds'],
  'search': ['Rechercher un build…', 'Search builds…', 'Buscar un build…'],
  'buildCount': ['{count} build(s)', '{count} build(s)', '{count} build(s)'],
  'profile': ['Profil Discord', 'Discord profile', 'Perfil de Discord'],
  'nickname': ['Pseudo affiché', 'Display nickname', 'Apodo visible'],
  'nicknameSaved': ['Pseudo mis à jour.', 'Nickname updated.', 'Apodo actualizado.'],
  'nicknameFailed': [
    'Impossible de mettre à jour le pseudo. Vérifie ta connexion.',
    'Could not update the nickname. Check your connection.',
    'No se pudo actualizar el apodo. Revisa tu conexión.',
  ],
  'signOut': ['Se déconnecter', 'Sign out', 'Cerrar sesión'],
  'signOutFailed': [
    'La déconnexion a rencontré une erreur.',
    'Something went wrong while signing out.',
    'Se produjo un error al cerrar sesión.',
  ],
  'language': ['Langue', 'Language', 'Idioma'],
  'auto': [
    'Automatique (langue du téléphone)',
    'Automatic (phone language)',
    'Automático (idioma del teléfono)',
  ],
  'storage': ['Stockage des builds', 'Build storage', 'Almacenamiento de builds'],
  'storageLine': [
    '{count} build(s) • {size}',
    '{count} build(s) • {size}',
    '{count} build(s) • {size}',
  ],
  'community': ['Communauté Discord', 'Discord community', 'Comunidad de Discord'],
  'about': ['À propos', 'About', 'Acerca de'],
  'credits': [
    'Basé sur ATLAS Link de cipherfps et ses contributeurs. Revive n’est ni affilié à Epic Games ni approuvé par lui.',
    'Based on ATLAS Link by cipherfps and contributors. Revive is not affiliated with or endorsed by Epic Games.',
    'Basado en ATLAS Link de cipherfps y colaboradores. Revive no está afiliado ni respaldado por Epic Games.',
  ],
  'edit': ['Modifier', 'Edit', 'Editar'],
  'save': ['Enregistrer', 'Save', 'Guardar'],
  'cancel': ['Annuler', 'Cancel', 'Cancelar'],
  'delete': ['Supprimer', 'Delete', 'Eliminar'],
  'deleteTitle': ['Supprimer ce build ?', 'Delete this build?', '¿Eliminar este build?'],
  'deleteMessage': [
    'Les fichiers extraits de « {name} » seront effacés du téléphone.',
    'The extracted files of “{name}” will be removed from the phone.',
    'Los archivos extraídos de «{name}» se borrarán del teléfono.',
  ],
  'deleteFailed': [
    'Impossible de supprimer les fichiers.',
    'Could not delete the files.',
    'No se pudieron eliminar los archivos.',
  ],
  'play': ['LANCER', 'LAUNCH', 'INICIAR'],
  'playInfo': [
    'Le lancement des builds Fortnite Android n’est pas encore implémenté.',
    'Launching Fortnite Android builds is not implemented yet.',
    'El inicio de builds de Fortnite para Android aún no está implementado.',
  ],
  'name': ['Nom du build', 'Build name', 'Nombre del build'],
  'version': ['Version', 'Version', 'Versión'],
  'description': ['Description', 'Description', 'Descripción'],
  'defaultDescription': [
    'Build importé dans Revive.',
    'Build imported into Revive.',
    'Build importado en Revive.',
  ],
  'unknownVersion': [
    'Version à identifier',
    'Unknown version',
    'Versión por identificar',
  ],
  'trailer': ['Lien du trailer YouTube', 'YouTube trailer link', 'Enlace del tráiler de YouTube'],
  'trailerOpen': ['VOIR LE TRAILER', 'WATCH TRAILER', 'VER TRÁILER'],
  'trailerSearch': [
    'Chercher le trailer sur YouTube',
    'Search for the trailer on YouTube',
    'Buscar el tráiler en YouTube',
  ],
  'files': ['{count} fichiers', '{count} files', '{count} archivos'],
  'structure': ['Structure : {value}', 'Structure: {value}', 'Estructura: {value}'],
  'missingFiles': [
    'Fichiers introuvables',
    'Files missing',
    'Archivos no encontrados',
  ],
  'imported': ['Build ajouté à la bibliothèque.', 'Build added to the library.', 'Build añadido a la biblioteca.'],
  'preparing': [
    'Préparation de l’archive…',
    'Preparing the archive…',
    'Preparando el archivo…',
  ],
  'extracting': ['Extraction : {percent} %', 'Extracting: {percent}%', 'Extrayendo: {percent} %'],
  'keepOpen': [
    'Garde l’application ouverte pendant l’import.',
    'Keep the app open during the import.',
    'Mantén la aplicación abierta durante la importación.',
  ],
  'invalidLink': ['Lien invalide.', 'Invalid link.', 'Enlace no válido.'],
  'linkFailed': [
    'Impossible d’ouvrir ce lien.',
    'Could not open this link.',
    'No se pudo abrir este enlace.',
  ],
  'sources': ['SOURCES DE BUILDS', 'BUILD SOURCES', 'FUENTES DE BUILDS'],
  'fortforgeAndroid': ['Builds Android FortForge', 'FortForge Android builds', 'Builds de Android en FortForge'],
  'otherArchive': ['Archive communautaire', 'Community archive', 'Archivo comunitario'],
  'archivesHint': [
    'Trouve un build Android, télécharge son ZIP puis importe-le ici.',
    'Find an Android build, download its ZIP and import it here.',
    'Busca un build de Android, descarga su ZIP e impórtalo aquí.',
  ],
  'catalog': ['CATALOGUE ANDROID FORTFORGE', 'FORTFORGE ANDROID CATALOG', 'CATÁLOGO ANDROID DE FORTFORGE'],
  'catalogError': [
    'Catalogue indisponible pour le moment. Tu peux ouvrir le site FortForge.',
    'The catalog is unavailable right now. You can open the FortForge website.',
    'El catálogo no está disponible ahora. Puedes abrir la web de FortForge.',
  ],
  'catalogCached': [
    'Hors ligne : dernière liste enregistrée.',
    'Offline: showing the last saved list.',
    'Sin conexión: se muestra la última lista guardada.',
  ],
  'retry': ['Réessayer', 'Retry', 'Reintentar'],
  'openFortforge': ['OUVRIR FORTFORGE', 'OPEN FORTFORGE', 'ABRIR FORTFORGE'],
  'releaseDate': ['Date de sortie : {value}', 'Release date: {value}', 'Fecha de salida: {value}'],
  'downloadSize': ['Taille : {value}', 'Size: {value}', 'Tamaño: {value}'],
  'downloads': ['{count} téléchargements', '{count} downloads', '{count} descargas'],
  'tags': ['Étiquettes : {value}', 'Tags: {value}', 'Etiquetas: {value}'],
  'zip_notZip': [
    'Ce fichier n’est pas une archive ZIP valide.',
    'This file is not a valid ZIP archive.',
    'Este archivo no es un ZIP válido.',
  ],
  'zip_corrupted': [
    'Archive endommagée ou incomplète.',
    'The archive is damaged or incomplete.',
    'El archivo está dañado o incompleto.',
  ],
  'zip_unsafePath': [
    'Archive refusée : chemin de fichier non sécurisé.',
    'Archive rejected: unsafe file path.',
    'Archivo rechazado: ruta de archivo no segura.',
  ],
  'zip_encrypted': [
    'Les ZIP protégés par mot de passe ne sont pas pris en charge.',
    'Password-protected ZIP files are not supported.',
    'No se admiten archivos ZIP con contraseña.',
  ],
  'zip_unsupported': [
    'Méthode de compression non prise en charge (utilise ZIP « Deflate »).',
    'Unsupported compression method (use ZIP “Deflate”).',
    'Método de compresión no admitido (usa ZIP «Deflate»).',
  ],
  'zip_symlink': [
    'Archive refusée : les liens symboliques ne sont pas autorisés.',
    'Archive rejected: symbolic links are not allowed.',
    'Archivo rechazado: no se permiten enlaces simbólicos.',
  ],
  'zip_empty': [
    'Le ZIP ne contient aucun fichier.',
    'The ZIP contains no files.',
    'El ZIP no contiene archivos.',
  ],
  'zip_tooLarge': [
    'Archive refusée : trop de fichiers ou contenu trop volumineux.',
    'Archive rejected: too many files or content too large.',
    'Archivo rechazado: demasiados archivos o contenido demasiado grande.',
  ],
  'zip_notABuild': [
    'Aucun build reconnu dans ce ZIP (FortniteGame, Engine, .pak…).',
    'No build recognised in this ZIP (FortniteGame, Engine, .pak…).',
    'No se reconoce ningún build en este ZIP (FortniteGame, Engine, .pak…).',
  ],
  'zip_duplicate': [
    'Ce build est déjà dans ta bibliothèque.',
    'This build is already in your library.',
    'Este build ya está en tu biblioteca.',
  ],
  'zip_noSpace': [
    'Pas assez d’espace libre sur le téléphone.',
    'Not enough free space on the phone.',
    'No hay suficiente espacio libre en el teléfono.',
  ],
  'zip_cancelled': ['Import annulé.', 'Import cancelled.', 'Importación cancelada.'],
  'zip_io': [
    'L’import a échoué. Vérifie le fichier et l’espace libre.',
    'Import failed. Check the file and free space.',
    'La importación falló. Comprueba el archivo y el espacio libre.',
  ],
};
