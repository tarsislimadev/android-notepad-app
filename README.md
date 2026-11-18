# Notepad for Android

A lightweight text editor for Android inspired by the core workflow of
NotePad++. Work with ordinary text files through the system file picker, and
manage notes stored in the app's internal SQLite database.

## Features

- Open public text files via Android's document/file picker.
- Edit text with standard mobile editing interactions.
- Save changes back to public files (with error handling).
- Create, read, update, and delete notes in an internal SQLite database.
- Key-value tags on every note.
- Browse, search, and filter notes by content or tags.
- Unsaved-edit preservation when the app is backgrounded or recreated.

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.13.0+
- An Android device or emulator (API 21+)

### Install dependencies

```sh
flutter pub get
```

## Build

### Analyze

```sh
flutter analyze
```

### Run tests

```sh
flutter test
```

### Build release APK

```sh
flutter build apk --release
```

The APK is output at `build/app/outputs/flutter-apk/app-release.apk`.

## Workflows

### Opening a public file

From the home screen, tap the **Open public file** icon in the top bar. Use
the system file picker to choose a `.txt`, `.md`, `.log`, or `.csv` file. The
file opens in the editor and can be saved back (a save dialog lets you choose
the location and filename).

### Creating a note

Tap the **+** floating action button on the home screen, enter a title and
content, optionally add tags, then tap **Save**. The note is stored in the app's
SQLite database.

### Editing a note

Tap any note in the home list to open it. Edit the title and content, add or
remove tags (key: value), then tap **Save** (check icon). Unsaved changes are
shown with an amber banner and preserved if you background the app.

### Deleting a note

Open a note and tap **Delete note** (trash icon) in the top bar, then confirm.

### Searching and filtering notes

- **Search:** type in the search bar on the home screen to filter notes by
  title or content.
- **Tag filter:** enter a tag key and value, then tap **Filter**. Tap **Clear**
  to return to the full list.

## Permissions

The app requests no extra Android permissions. File access uses the system
Storage Access Framework (file picker), and notes are stored in the app's
private database directory.

## Project structure

- `lib/main.dart` — app entry point, provider setup, routing.
- `lib/data/` — data layer: `note_model.dart`, `app_database.dart`,
  `note_repository.dart`, `file_service.dart`.
- `lib/app_state/` — `note_notifier.dart` (provider state, unsaved edits).
- `lib/screens/` — `home_screen.dart`, `note_editor_screen.dart`.
- `lib/widgets/` — reusable UI components.
- `test/data/` — tests for note persistence, tags, search/filter, and file
  operations.

## License

[MIT](./LICENSE)
