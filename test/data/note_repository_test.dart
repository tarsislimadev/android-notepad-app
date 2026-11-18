import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:notepad/data/app_database.dart';
import 'package:notepad/data/note_model.dart';
import 'package:notepad/data/note_repository.dart';

void main() {
  late NoteRepository repository;

  setUp(() {
    databaseFactory = databaseFactoryFfi;
    final db = AppDatabase.forTesting();
    repository = NoteRepository(db);
  });

  tearDown(() async {
    await repository.close();
  });

  Future<int> createNote({
    String title = 'Note',
    String content = 'Content',
    Map<String, String> tags = const {},
  }) async {
    return repository.createNote(title, content, tags: tags);
  }

  test('create and retrieve a note', () async {
    final id = await createNote(
      title: 'Grocery list',
      content: 'milk, eggs',
      tags: {'category': 'shopping'},
    );

    final note = await repository.getNoteById(id);
    expect(note, isNotNull);
    expect(note!.title, 'Grocery list');
    expect(note.content, 'milk, eggs');
    expect(note.tags, {'category': 'shopping'});
    expect(note.createdAt, isNotNull);
    expect(note.updatedAt, isNotNull);
  });

  test('getAllNotes returns notes ordered by updated_at descending', () async {
    final a = await createNote(title: 'A', content: 'a');
    await Future.delayed(const Duration(milliseconds: 10));
    final b = await createNote(title: 'B', content: 'b');

    final notes = await repository.getAllNotes();
    expect(notes.length, 2);
    expect(notes.first.id, b);
    expect(notes.last.id, a);
  });

  test('update a note replaces content and tags', () async {
    final id = await createNote(
      title: 'Before',
      content: 'old',
      tags: {'old': 'tag'},
    );

    final rows = await repository.saveNote(Note(
      id: id,
      title: 'After',
      content: 'new',
      createdAt: DateTime(2020, 1, 1),
      updatedAt: DateTime.now(),
      tags: {'new': 'tag'},
    ));
    expect(rows, 1);

    final note = await repository.getNoteById(id);
    expect(note!.title, 'After');
    expect(note.content, 'new');
    expect(note.tags, {'new': 'tag'});
    expect(note.createdAt, DateTime(2020, 1, 1));
  });

  test('delete a note removes it and its tags', () async {
    final id = await createNote(title: 'Temp', tags: {'k': 'v'});
    await repository.deleteNote(id);

    expect(await repository.getNoteById(id), isNull);
    final all = await repository.getAllNotes();
    expect(all.isEmpty, true);
  });

  test('search notes matches title or content', () async {
    await createNote(title: 'Alpha', content: 'nothing');
    await createNote(title: 'Beta', content: 'alpha keyword here');
    await createNote(title: 'Gamma', content: 'other');

    final byTitle = await repository.searchNotes('Alpha');
    expect(byTitle.length, 2);

    final byContent = await repository.searchNotes('keyword');
    expect(byContent.length, 1);
    expect(byContent.first.title, 'Beta');

    final empty = await repository.searchNotes('zzz');
    expect(empty.isEmpty, true);
  });

  test('filter notes by tag key and value', () async {
    await createNote(title: 'T1', tags: {'priority': 'high'});
    await createNote(title: 'T2', tags: {'priority': 'low'});
    await createNote(title: 'T3', tags: {'status': 'open'});

    final high = await repository.getNotesByTag('priority', 'high');
    expect(high.length, 1);
    expect(high.first.title, 'T1');

    final byKey = await repository.getNotesByTagKey('priority');
    expect(byKey.length, 2);
  });

  test('tags default to empty map', () async {
    final id = await createNote(title: 'Plain');
    final note = await repository.getNoteById(id);
    expect(note!.tags, isEmpty);
  });
}
