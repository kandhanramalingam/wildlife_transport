# Project Release Rulebook

## APK versioning

- Whenever an APK is requested, increase the app version in `pubspec.yaml` before building it.
- Keep the version shown on the Profile screen synchronized with the `pubspec.yaml` release version.
- Return a copy of the APK in the repository root named `AWA-Transport-v<version>-debug.apk` for debug builds or `AWA-Transport-v<version>-release.apk` for release builds.
- Never overwrite an APK from an earlier version; retain versioned artifacts so they are easy to distinguish.
- Build APKs with both `config/dev.json` and `config/maps.local.json` so API and embedded Maps configuration are included.
