# Revive Launcher — Android prototype

This is an Android-oriented Flutter prototype using the supplied Revive logo and a dark desktop-launcher-inspired visual direction (ATLAS-style layout conventions, adapted for mobile).

## Included in this iteration

- Revive branding and supplied logo.
- Home, Builds, Archives and Settings navigation.
- Dark hero panel, library cards, build details sheet and profile placeholder.
- ZIP picker and extraction into app-private storage.
- Basic archive inspection for `Engine/` and `FortniteGame/` folders, plus a best-effort version guess from the archive name/path.
- Season artwork lookup using the existing `assets/seasons/SeasonN.jpg` images in the source repository (loaded from the public repository URL for this prototype).
- GitHub Actions workflow to build an Android APK.

## Not implemented yet

- Offline bundling of the season artwork (the prototype currently loads it from the public source repository).
- Persistent build database and large-archive streaming extraction.
- Discord/Supabase mobile OAuth callback integration.
- Android-compatible Fortnite runtime/launch mechanism.
- Actual build launch action (the current JOUER button is explicitly a placeholder).

The ZIP is treated as a game build archive, not as an APK/OBB installer. This prototype extracts its contents and inspects the folder structure. The current picker reads the ZIP into memory, so it is only suitable for small test archives; production support for very large Fortnite archives must use streaming extraction and progress/cancellation before it is used with multi-gigabyte files.

## Build

Push this directory to a GitHub repository. The workflow in `.github/workflows/android.yml` uses GitHub Actions to build and upload the release APK. No APK has been compiled in this workspace.
