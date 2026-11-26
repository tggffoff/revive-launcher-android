# Revive Launcher — Android

Projet Flutter Android autonome. Il ne réutilise pas le code du launcher Windows.

## Fonctions de cette version

- Interface mobile Revive sombre violet/bleu, adaptée aux écrans Android.
- Connexion Discord obligatoire via Supabase OAuth, ouverture du navigateur puis retour par le deep link `revive://auth/callback`.
- Profil Discord : avatar fourni par Discord (non modifiable dans l'application), pseudo d'affichage modifiable.
- Accueil, bibliothèque, archives et paramètres.
- Import de builds **ZIP uniquement** (pas d'APK/OBB), extraction dans l'espace privé de l'application, contrôle des chemins ZIP, détection indicative de version et détection des dossiers Engine/FortniteGame.
- Fiche de build modifiable : nom, version, description et lien YouTube.
- Bibliothèque et préférences sauvegardées localement.
- Langues français, anglais et espagnol ; choix automatique de la langue du téléphone, anglais par défaut.
- Accès au catalogue FortForge : https://fortforge.co.uk
- Bouton LANCER visible mais volontairement provisoire : le runtime nécessaire pour exécuter d'anciens builds Fortnite n'est pas fourni par Android ni par un ZIP de données.

## Configuration Discord requise

1. Créer/configurer un projet Supabase.
2. Dans Supabase Authentication > Providers, activer Discord et renseigner les identifiants OAuth de l'application Discord.
3. Ajouter `revive://auth/callback` aux URL de redirection autorisées de Supabase.
4. Dans les paramètres du dépôt GitHub, ajouter les Actions secrets :
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

Sans ces secrets, l'APK peut être compilé, mais la connexion Discord reste désactivée dans l'application. Ne jamais mettre le secret OAuth Discord privé dans le code ou dans GitHub Actions.

## Import ZIP : limites actuelles

L'import utilise une lecture en mémoire. Pour éviter de faire planter le téléphone, les ZIP de plus de 400 Mo et les archives dont le contenu extrait dépasse 2 Go sont refusés. Les archives multi-gigaoctets nécessitent une extraction en flux avec progression et annulation ; cette fonction n'est pas incluse dans cette version.

La version reconnue est une estimation à partir du nom du ZIP et de ses chemins internes. Vérifie-la dans la fiche du build. Les miniatures et bandes-annonces ne sont pas récupérées automatiquement depuis un catalogue distant : la fiche permet de renseigner un lien YouTube manuellement.

## Compilation

Le workflow GitHub Actions génère l'APK release, lance l'analyse Dart et les tests widget, puis publie l'APK en artefact de workflow.
