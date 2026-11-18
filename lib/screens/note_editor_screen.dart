import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state/note_notifier.dart';
import '../widgets/widgets.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _exitConfirmed = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _syncFromState();
    _titleController.addListener(() {
      if (!mounted) return;
      context.read<NoteNotifier>().setTitle(_titleController.text);
    });
    _contentController.addListener(() {
      if (!mounted) return;
      context.read<NoteNotifier>().setContent(_contentController.text);
    });
  }

  void _syncFromState() {
    final state = context.read<NoteNotifier>().state;
    _titleController.text = state.editingTitle;
    _contentController.text = state.editingContent;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteNotifier>(
      builder: (context, notifier, child) {
        final state = notifier.state;
        return PopScope(
          canPop: !state.hasUnsavedChanges || _exitConfirmed,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (!state.hasUnsavedChanges) return;
            final save = await _showUnsavedDialog(context);
            if (!context.mounted) return;
            if (save == true) {
              await notifier.saveCurrentNote();
            }
            if (save != null) {
              if (!context.mounted) return;
              setState(() => _exitConfirmed = true);
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Save',
                  onPressed: () async {
                    final id = await notifier.saveCurrentNote();
                    if (id != null && context.mounted) {
                      Navigator.pop(context, id);
                    }
                  },
                ),
                if (state.editingNote != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete note',
                    onPressed: () async {
                      final confirm = await _showDeleteConfirm(context);
                      if (confirm == true && context.mounted) {
                        await notifier.deleteCurrentNote();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showMenu(context, notifier),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        border: InputBorder.none,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                ),
                _buildTagsSection(notifier, state),
                if (state.hasUnsavedChanges)
                  _UnsavedBanner(
                    onSave: () async => await notifier.saveCurrentNote(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagsSection(NoteNotifier notifier, NoteState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Tags (key: value)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...state.editingTags.entries.map((entry) => TagChip(
                  tagKey: entry.key,
                  tagValue: entry.value,
                  onRemove: () => notifier.removeTag(entry.key),
                )),
            const _NewTagRow(),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
            'This note will be permanently removed. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showUnsavedDialog(BuildContext context) {
    return showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
            'You have unsaved changes. Save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, NoteNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open public file'),
            onTap: () {
              Navigator.pop(context);
              notifier.openPublicFile();
            },
          ),
        ],
      ),
    );
  }
}

class _UnsavedBanner extends StatelessWidget {
  final Future<void> Function() onSave;

  const _UnsavedBanner({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning, size: 18, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unsaved changes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => onSave(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NewTagRow extends StatefulWidget {
  const _NewTagRow();

  @override
  State<_NewTagRow> createState() => _NewTagRowState();
}

class _NewTagRowState extends State<_NewTagRow> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 75,
          child: TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              hintText: 'key',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 75,
          child: TextField(
            controller: _valueController,
            decoration: const InputDecoration(
              hintText: 'value',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.add, size: 20),
          onPressed: () {
            final key = _keyController.text.trim();
            final value = _valueController.text.trim();
            if (key.isEmpty || value.isEmpty) return;
            context.read<NoteNotifier>().addOrUpdateTag(key, value);
            _keyController.clear();
            _valueController.clear();
          },
        ),
      ],
    );
  }
}
