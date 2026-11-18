import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state/note_notifier.dart';
import 'data/app_database.dart';
import 'data/file_service.dart';
import 'data/note_repository.dart';
import 'screens/home_screen.dart';
import 'screens/note_editor_screen.dart';

void main() {
  runApp(const NotepadApp());
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) {
        final db = AppDatabase();
        return NoteNotifier(
          NoteRepository(db),
          FileService(),
        );
      },
      dispose: (_, notifier) => notifier.close(),
      child: MaterialApp(
        title: 'Notepad',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        home: const HomeScreen(),
        routes: {
          '/editor': (context) => const NoteEditorScreen(),
        },
      ),
    );
  }
}
