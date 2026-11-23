# Copilot instructions

## Project overview

This repository is a Flutter Android app named `notepad` (Dart SDK `^3.13.0`). The app has two distinct editing flows:

- **Internal notes** are stored in the app-private SQLite database.
- **Public files** are opened and saved through the Android/system file picker.

The application starts in `lib/main.dart`, which creates the `AppDatabase`, `NoteRepository`, and `FileService`, then injects a single `NoteNotifier` with `provider`. The UI is organized into:

- `lib/screens/`: `HomeScreen` for loading/searching/filtering notes and `NoteEditorScreen` for editing.
- `lib/app_state/`: `NoteNotifier` and immutable `NoteState`, including loading/error states and unsaved-edit tracking.
- `lib/data/`: `Note` model, SQLite setup, repository operations, and public-file picker service.
- `lib/widgets/`: reusable empty, loading, error, list-item, and tag-chip widgets.

Internal-note persistence is layered as `NoteNotifier -> NoteRepository -> AppDatabase`. Notes and tags use separate SQLite tables (`notes` and `note_tags`); tag maps are assembled when notes are read. Public files bypass the database and use `FileService`, with supported extensions `txt`, `md`, `log`, and `csv`.

## Commands

Run these from the repository root:

```sh
flutter pub get
flutter analyze
flutter test
flutter test test/data/note_repository_test.dart
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The GitHub Actions workflow in `.github/workflows/release-apk.yml` builds the same APK on `v*` tag pushes or manual dispatch, using Java 17 and Flutter stable, then publishes it to a GitHub Release.

## Repository-specific conventions

- Use package imports such as `package:notepad/data/note_model.dart`; the package name is `notepad`.
- Keep persistence concerns in `AppDatabase` and `NoteRepository`; screens should interact with notes through `NoteNotifier` rather than querying SQLite directly.
- Keep public-file behavior in `FileService` and distinguish it from internal-note state using `editingFilePath` versus `editingNote`.
- `NoteState` is immutable and updated with `copyWith`; state-changing notifier methods call `notifyListeners()`.
- Preserve explicit `ViewState` handling (`idle`, `loading`, `success`, `error`) and user-facing error messages when adding asynchronous operations.
- Note tags are `Map<String, String>` values in Dart but normalized into the `note_tags` table. When updating a note, replace its complete tag set rather than merging individual database rows.
- Database tests use `AppDatabase.forTesting()` with `sqflite_common_ffi`; initialize `databaseFactory = databaseFactoryFfi` in test setup and close the repository in teardown.
- The analyzer uses `package:flutter_lints/flutter.yaml` and excludes platform/build directories. Follow the existing lint configuration in `analysis_options.yaml`.
- The app requests no extra Android permissions. Public-file access should continue to use the system Storage Access Framework/file picker.
