# AGENTS.md

## Project
- Flutter app package `notepad` (Dart/Flutter SDK constraint: `^3.13.0` in `pubspec.yaml`).
- Entrypoint: `lib/main.dart`. Current `lib/` and `test/widget_test.dart` are the default Flutter counter scaffold.
- No CI workflows, code generation, or repo-local agent/Kilo config files are present.

## Commands
- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- All tests: `flutter test`
- Single test file: `flutter test test/widget_test.dart`

## Conventions / gotchas
- Package imports use `package:notepad/...` (matches `pubspec.yaml` `name`).
- Lints: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` and excludes `build/**` and platform directories (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`) from analysis.
- `README.md` is generic Flutter template text; prefer `pubspec.yaml`, `analysis_options.yaml`, and source/tests as executable/current sources of truth.
- Dependencies are minimal (`flutter`, `cupertino_icons`, `flutter_lints`, `flutter_test` only). Add and configure required packages/tooling (e.g. Drift/build_runner/Riverpod) in `pubspec.yaml` before implementing features that depend on them.
