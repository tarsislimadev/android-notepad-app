import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'note_model.dart';

class AppDatabase {
  static Database? _db;

  final Future<Database> Function() _open;

  AppDatabase._internal(this._open);

  factory AppDatabase() => AppDatabase._internal(_openDefault);

  static Future<Database> _openDefault() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final path = join(dbDir.path, 'notepad.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  AppDatabase.forTesting() : _open = _openInMemory;

  static Future<Database> _openInMemory() async {
    return openDatabase(
      ':memory:',
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE note_tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC)');
    await db.execute('CREATE INDEX idx_note_tags_note_id ON note_tags(note_id)');
  }

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert('notes', note.toMap()..remove('id'));
  }

  Future<void> insertTags(int noteId, Map<String, String> tags) async {
    if (tags.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final entry in tags.entries) {
      batch.insert('note_tags', {
        'note_id': noteId,
        'key': entry.key,
        'value': entry.value,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<int> updateNote(Note note) async {
    if (note.id == null) return 0;
    final db = await database;
    return db.update(
      'notes',
      note.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> replaceTags(int noteId, Map<String, String> tags) async {
    final db = await database;
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [noteId]);
    await insertTags(noteId, tags);
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> allNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return _notesFromMaps(db, maps);
  }

  Future<List<Note>> searchNotes(String query) async {
    if (query.isEmpty) return allNotes();
    final db = await database;
    final like = '%$query%';
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: [like, like],
      orderBy: 'updated_at DESC',
    );
    return _notesFromMaps(db, maps);
  }

  Future<List<Note>> notesByTag(String key, String value) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT n.* FROM notes n
      JOIN note_tags t ON t.note_id = n.id
      WHERE t.key = ? AND t.value = ?
      ORDER BY n.updated_at DESC
    ''', [key, value]);
    return _notesFromMaps(db, maps);
  }

  Future<List<Note>> notesByTagKey(String key) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT n.* FROM notes n
      JOIN note_tags t ON t.note_id = n.id
      WHERE t.key = ?
      GROUP BY n.id
      ORDER BY n.updated_at DESC
    ''', [key]);
    return _notesFromMaps(db, maps);
  }

  Future<Note?> noteById(int id) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return (await _notesFromMaps(db, maps)).first;
  }

  Future<Map<String, String>> tagsForNote(int noteId) async {
    final db = await database;
    final maps = await db.query(
      'note_tags',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    return {for (final m in maps) m['key'] as String: m['value'] as String};
  }

  Future<List<Note>> _notesFromMaps(Database db, List<Map<String, Object?>> maps) async {
    final notes = <Note>[];
    for (final m in maps) {
      final note = Note.fromMap(m);
      final tags = await tagsForNote(note.id!);
      notes.add(note.copyWith(tags: tags));
    }
    return notes;
  }
}
