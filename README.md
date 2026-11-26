# Revive Launcher — Android

Application Flutter Android indépendante du launcher Windows.

## Fonctionnalités

- Interface mobile sombre Revive : Accueil, Bibliothèque, Archives et Paramètres.
- Import de builds Fortnite Android au format ZIP uniquement.
- Détection indicative de la version à partir du nom de l'archive et des chemins contenus dans le ZIP.
- Extraction dans l'espace privé de l'application, vérification de chemins ZIP et persistance de la bibliothèque.
- Connexion Discord via Supabase OAuth (PKCE), retour par le lien profond `revive://auth/callback`.
- Avatar Discord, pseudo d'affichage modifiable localement et choix FR / EN / ES avec détection automatique de la langue du téléphone.
- Accès au catalogue Android de FortForge : https://fortforge.co.uk/builds/android
- Bouton JOUER présent comme emplacement d'interface, mais le moteur de lancement Android n'est pas implémenté.

## Configuration Discord

Créer un projet Supabase et activer le fournisseur Discord dans Authentication > Providers. Configurer l'URL de redirection autorisée `revive://auth/callback` dans les URL de redirection Supabase et configurer les identifiants OAuth Discord côté Supabase.

Ajouter les secrets GitHub Actions suivants :
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Le client n'intègre aucun secret privé Discord. Seule la clé anon publique Supabase est passée au build.

## Limites connues

- L'import ZIP actuel lit le contenu de l'archive en mémoire. Il convient aux archives de test de taille raisonnable ; l'extraction en flux avec progression/annulation est nécessaire avant de traiter des archives Fortnite de plusieurs Go.
- La version détectée est une estimation basée sur les noms de fichiers et chemins ZIP ; elle doit être vérifiée dans la fiche du build.
- Le catalogue FortForge est ouvert dans le navigateur ; aucune API non documentée n'est supposée.
- Le bouton JOUER ne démarre pas Fortnite. Android ne fournit pas de moteur générique permettant de lancer directement un ancien build PC/Android.

## Compilation

Le workflow GitHub Actions génère un APK release et le publie comme artefact de workflow. Les secrets Supabase sont facultatifs pour compiler, mais nécessaires pour activer la connexion Discord.
