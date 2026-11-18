import 'package:flutter/foundation.dart';

import '../data/file_service.dart';
import '../data/note_model.dart';
import '../data/note_repository.dart';

enum ViewState { idle, loading, success, error }

@immutable
class NoteState {
  final List<Note> notes;
  final Note? editingNote;
  final String? editingFilePath;
  final String editingTitle;
  final String editingContent;
  final Map<String, String> editingTags;
  final ViewState viewState;
  final String? error;
  final bool hasUnsavedChanges;

  const NoteState({
    this.notes = const [],
    this.editingNote,
    this.editingFilePath,
    this.editingTitle = '',
    this.editingContent = '',
    this.editingTags = const {},
    this.viewState = ViewState.idle,
    this.error,
    this.hasUnsavedChanges = false,
  });

  NoteState copyWith({
    List<Note>? notes,
    Note? editingNote,
    bool clearEditingNote = false,
    String? editingFilePath,
    bool clearEditingFilePath = false,
    String? editingTitle,
    String? editingContent,
    Map<String, String>? editingTags,
    ViewState? viewState,
    String? error,
    bool clearError = false,
    bool? hasUnsavedChanges,
  }) {
    return NoteState(
      notes: notes ?? this.notes,
      editingNote: clearEditingNote ? null : editingNote ?? this.editingNote,
      editingFilePath: clearEditingFilePath
          ? null
          : editingFilePath ?? this.editingFilePath,
      editingTitle: editingTitle ?? this.editingTitle,
      editingContent: editingContent ?? this.editingContent,
      editingTags: editingTags ?? this.editingTags,
      viewState: viewState ?? this.viewState,
      error: clearError ? null : error ?? this.error,
      hasUnsavedChanges:
          hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

class NoteNotifier extends ChangeNotifier {
  final NoteRepository _repository;
  final FileService _fileService;

  NoteState _state = const NoteState();

  NoteState get state => _state;

  NoteNotifier(this._repository, this._fileService);

  Future<void> loadNotes() async {
    _state = _state.copyWith(viewState: ViewState.loading, clearError: true);
    notifyListeners();
    try {
      final notes = await _repository.getAllNotes();
      _state = _state.copyWith(
        notes: notes,
        viewState: ViewState.success,
      );
    } catch (e) {
      _state = _state.copyWith(
        viewState: ViewState.error,
        error: 'Failed to load notes: $e',
      );
    }
    notifyListeners();
  }

  Future<List<Note>> searchNotes(String query) async {
    _state = _state.copyWith(viewState: ViewState.loading, clearError: true);
    notifyListeners();
    try {
      final notes = query.isEmpty
          ? await _repository.getAllNotes()
          : await _repository.searchNotes(query);
      _state = _state.copyWith(
        notes: notes,
        viewState: ViewState.success,
      );
      return notes;
    } catch (e) {
      _state = _state.copyWith(
        viewState: ViewState.error,
        error: 'Search failed: $e',
      );
      return [];
    } finally {
      notifyListeners();
    }
  }

  Future<List<Note>> filterByTag(String key, String value) async {
    _state = _state.copyWith(viewState: ViewState.loading, clearError: true);
    notifyListeners();
    try {
      final notes = await _repository.getNotesByTag(key, value);
      _state = _state.copyWith(
        notes: notes,
        viewState: ViewState.success,
      );
      return notes;
    } catch (e) {
      _state = _state.copyWith(
        viewState: ViewState.error,
        error: 'Filter failed: $e',
      );
      return [];
    } finally {
      notifyListeners();
    }
  }

  void startNewNote() {
    _state = _state.copyWith(
      clearEditingNote: true,
      editingFilePath: null,
      editingTitle: '',
      editingContent: '',
      editingTags: const {},
      hasUnsavedChanges: false,
      viewState: ViewState.idle,
      clearError: true,
    );
    notifyListeners();
  }

  Future<void> openNote(Note note) async {
    _state = _state.copyWith(
      editingNote: note,
      editingFilePath: null,
      editingTitle: note.title,
      editingContent: note.content,
      editingTags: Map<String, String>.from(note.tags),
      hasUnsavedChanges: false,
      viewState: ViewState.idle,
      clearError: true,
    );
    notifyListeners();
  }

  Future<void> openPublicFile() async {
    _state = _state.copyWith(viewState: ViewState.loading, clearError: true);
    notifyListeners();
    try {
      final result = await _fileService.pickTextFile();
      if (result == null) {
        _state = _state.copyWith(viewState: ViewState.idle);
        notifyListeners();
        return;
      }
      _state = _state.copyWith(
        editingNote: null,
        editingFilePath: result.path,
        editingTitle: result.name,
        editingContent: result.content,
        editingTags: const {},
        hasUnsavedChanges: false,
        viewState: ViewState.success,
      );
    } catch (e) {
      _state = _state.copyWith(
        viewState: ViewState.error,
        error: 'Failed to open file: $e',
      );
    }
    notifyListeners();
  }

  void setTitle(String title) {
    if (_state.editingTitle == title) return;
    _state = _state.copyWith(
      editingTitle: title,
      hasUnsavedChanges: true,
    );
    notifyListeners();
  }

  void setContent(String content) {
    if (_state.editingContent == content) return;
    _state = _state.copyWith(
      editingContent: content,
      hasUnsavedChanges: true,
    );
    notifyListeners();
  }

  void setTags(Map<String, String> tags) {
    _state = _state.copyWith(
      editingTags: Map<String, String>.from(tags),
      hasUnsavedChanges: true,
    );
    notifyListeners();
  }

  void addOrUpdateTag(String key, String value) {
    final tags = Map<String, String>.from(_state.editingTags)
      ..[key] = value;
    setTags(tags);
  }

  void removeTag(String key) {
    final tags = Map<String, String>.from(_state.editingTags)..remove(key);
    setTags(tags);
  }

  Future<int?> saveCurrentNote() async {
    final title = _state.editingTitle.trim();
    if (title.isEmpty) {
      _state = _state.copyWith(
        viewState: ViewState.error,
        error: 'Title cannot be empty.',
      );
      notifyListeners();
      return null;
    }

    // Editing an existing internal note.
    if (_state.editingNote != null && _state.editingFilePath == null) {
      final note = _state.editingNote!.copyWith(
        title: title,
        content: _state.editingContent,
        tags: Map<String, String>.from(_state.editingTags),
      );
      final rows = await _repository.saveNote(note);
      _markSaved(note.copyWith(id: _state.editingNote!.id));
      return rows;
    }

    // Editing a public file: write back via the system save dialog.
    if (_state.editingFilePath != null) {
      try {
        final saved = await _fileService.saveTextFile(
          content: _state.editingContent,
          suggestedName: _state.editingTitle.isNotEmpty
              ? '${_state.editingTitle}.txt'
              : 'note.txt',
        );
        if (saved == null) return null;
        _state = _state.copyWith(
          editingFilePath: saved,
          editingTitle: _state.editingTitle,
          hasUnsavedChanges: false,
          viewState: ViewState.success,
        );
        notifyListeners();
        return 1;
      } catch (e) {
        _state = _state.copyWith(
          viewState: ViewState.error,
          error: 'Failed to save file: $e',
        );
        notifyListeners();
        return null;
      }
    }

    // Creating a new internal note.
    try {
      final id = await _repository.createNote(
        title,
        _state.editingContent,
        tags: Map<String, String>.from(_state.editingTags),
      );
      final saved = await _repository.getNoteById(id);
      _markSaved(saved!);
      return id;
    } catch (e) {
      _state = _state.copyWith(
        viewState: ViewState.error,
        error: 'Failed to save note: $e',
      );
      notifyListeners();
      return null;
    }
  }

  void _markSaved(Note note) {
    _state = _state.copyWith(
      editingNote: note,
      editingFilePath: null,
      editingTitle: note.title,
      editingContent: note.content,
      editingTags: Map<String, String>.from(note.tags),
      hasUnsavedChanges: false,
      viewState: ViewState.success,
    );
    notifyListeners();
  }

  Future<void> deleteCurrentNote() async {
    final id = _state.editingNote?.id;
    if (id == null) return;
    _state = _state.copyWith(viewState: ViewState.loading);
    notifyListeners();
    try {
      await _repository.deleteNote(id);
      startNewNote();
      await loadNotes();
    } catch (e) {
      _state = _state.copyWith(
        viewState: ViewState.error,
        error: 'Failed to delete note: $e',
      );
    }
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  Future<void> close() async {
    await _repository.close();
  }
}
