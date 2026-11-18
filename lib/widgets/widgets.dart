import 'package:flutter/material.dart';

import '../data/note_model.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteListItem({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tags = note.tags;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: const Icon(Icons.note),
      title: Text(
        note.title.isEmpty ? '(untitled)' : note.title,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (note.content.isNotEmpty)
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.entries
                  .map(
                    (e) => Chip(
                      label: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      trailing: Text(
        _formatTime(note.updatedAt),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
}

class TagChip extends StatelessWidget {
  final String tagKey;
  final String tagValue;
  final VoidCallback onRemove;

  const TagChip({
    super.key,
    required this.tagKey,
    required this.tagValue,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$tagKey: $tagValue',
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
    );
  }
}
