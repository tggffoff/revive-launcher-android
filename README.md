# REVIVE Launcher — Android

Application Flutter : version Android du launcher REVIVE.

> Basé sur [ATLAS Link](third_party/ATLAS-Link-LICENSE.txt) de cipherfps et ses
> contributeurs. REVIVE n'est ni affilié à Epic Games ni approuvé par lui.

## Fonctions

- Connexion Discord (Supabase OAuth PKCE) dans le navigateur, retour par
  `revive://auth/callback`, session chiffrée et restaurée au démarrage.
- Profil : avatar, nom Discord, pseudo modifiable (`user_metadata.pseudo`, comme
  sur Windows), déconnexion.
- Accueil, bibliothèque (bouton +), catalogue, paramètres.
- Import de builds ZIP : extraction en flux (ZIP et ZIP64), progression,
  annulation, vérification CRC, refus des archives dangereuses, des doublons et
  des archives sans build reconnu.
- Version reconnue à l'import : `++Fortnite+Release-X.Y` lu dans les fichiers du
  build (ou dans un APK présent dans le ZIP), sinon nom du ZIP et des dossiers ;
  le visuel de la saison (1 à 41) s'affiche automatiquement.
- Catalogue Android lu depuis l'API publique FortForge, avec copie hors ligne ;
  liens FortForge, Carbon et Helix.
- Français, anglais, espagnol (langue du téléphone, anglais par défaut).
- Le bouton LANCER reste provisoire : le lancement n'est pas implémenté.

## Réglage Supabase (obligatoire pour la connexion)

Dans le tableau de bord Supabase : **Authentication > URL Configuration >
Redirect URLs**, ajouter `revive://auth/callback`. Le fournisseur Discord doit
être activé dans **Authentication > Providers**.

L'URL et la clé publique du projet sont dans `lib/config.dart`. Aucun secret
GitHub n'est nécessaire. Ne jamais y mettre de clé `service_role` ni le secret
client Discord.

## Compilation

GitHub > onglet **Actions** > **Android APK** > **Run workflow**. L'APK se
télécharge dans la section **Artifacts** de l'exécution terminée.

En local (Flutter 3.41) :

```
flutter create --platforms=android --org com.revive --project-name revive_launcher .
python3 tool/configure_android.py
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release
```

## Limites connues

- L'APK est signé avec la clé de debug générée à chaque compilation : pour
  installer une nouvelle version, il faut d'abord désinstaller l'ancienne, ce
  qui efface les builds importés. Une clé de signature fixe est à ajouter.
- Pendant un import, le téléphone copie d'abord le ZIP puis l'extrait : prévoir
  de l'espace libre pour le ZIP deux fois et les fichiers extraits. Garder
  l'application ouverte.
- Le « Discord Gate » de Windows (réseau Tailscale) n'est pas porté.
