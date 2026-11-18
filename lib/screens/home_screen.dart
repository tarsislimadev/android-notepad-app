import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/note_notifier.dart';
import '../widgets/widgets.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _tagKey = '';
  String _tagValue = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteNotifier>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notepad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Open public file',
            onPressed: () => context.read<NoteNotifier>().openPublicFile(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildTagFilter(context),
          Expanded(
            child: Consumer<NoteNotifier>(
              builder: (context, notifier, child) {
                final state = notifier.state;
                if (state.viewState == ViewState.error) {
                  return ErrorState(
                    message: state.error ?? 'An error occurred.',
                    onRetry: () => notifier.loadNotes(),
                  );
                }
                if (state.viewState == ViewState.loading &&
                    state.notes.isEmpty) {
                  return const LoadingState();
                }
                if (state.notes.isEmpty) {
                  return EmptyState(
                    title: 'No notes yet',
                    message:
                        'Tap the + button to create a note, or open a public file.',
                  );
                }
                return ListView.builder(
                  itemCount: state.notes.length,
                  itemBuilder: (context, index) {
                    final note = state.notes[index];
                    return NoteListItem(
                      note: note,
                      onTap: () {
                        context.read<NoteNotifier>().openNote(note);
                        Navigator.pushNamed(context, '/editor');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<NoteNotifier>().startNewNote();
          Navigator.pushNamed(context, '/editor');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search notes by title or content',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<NoteNotifier>().searchNotes('');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (query) =>
            context.read<NoteNotifier>().searchNotes(query),
      ),
    );
  }

  Widget _buildTagFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Text('Filter by tag:'),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'key',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                filled: true,
              ),
              onChanged: (v) => setState(() => _tagKey = v),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'value',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderSide: BorderSide.none),
                filled: true,
              ),
              onChanged: (v) => setState(() => _tagValue = v),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: (_tagKey.isNotEmpty && _tagValue.isNotEmpty)
                ? () => context
                    .read<NoteNotifier>()
                    .filterByTag(_tagKey, _tagValue)
                : null,
            child: const Text('Filter'),
          ),
          const SizedBox(width: 4),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _tagKey = '';
                _tagValue = '';
              });
              context.read<NoteNotifier>().loadNotes();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
