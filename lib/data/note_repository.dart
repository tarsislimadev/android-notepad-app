import 'app_database.dart';
import 'note_model.dart';

class NoteRepository {
  final AppDatabase _db;

  NoteRepository(this._db);

  AppDatabase get database => _db;

  Future<List<Note>> getAllNotes() => _db.allNotes();

  Future<List<Note>> searchNotes(String query) => _db.searchNotes(query);

  Future<List<Note>> getNotesByTag(String key, String value) =>
      _db.notesByTag(key, value);

  Future<List<Note>> getNotesByTagKey(String key) => _db.notesByTagKey(key);

  Future<Note?> getNoteById(int id) => _db.noteById(id);

  Future<int> createNote(String title, String content,
      {Map<String, String> tags = const {}}) async {
    final now = DateTime.now();
    final note = Note(
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
    final id = await _db.insertNote(note);
    await _db.insertTags(id, tags);
    return id;
  }

  Future<int> saveNote(Note note) async {
    final now = DateTime.now();
    final updated = note.copyWith(updatedAt: now);
    final rows = await _db.updateNote(updated);
    if (updated.id != null) {
      await _db.replaceTags(updated.id!, updated.tags);
    }
    return rows;
  }

  Future<int> deleteNote(int id) => _db.deleteNote(id);

  Future<void> close() => _db.close();
}
