import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class FileResult {
  final String path;
  final String name;
  final String content;
  final DateTime? modifiedAt;

  FileResult({
    required this.path,
    required this.name,
    required this.content,
    this.modifiedAt,
  });
}

class FileService {
  /// Lets the user pick a public text file via the system file picker and
  /// returns its contents. Returns null if the user cancelled.
  Future<FileResult?> pickTextFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Open text file',
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md', 'log', 'csv'],
    );
    if (file == null) return null;

    final content = await _readPlatformFile(file);
    if (content == null) return null;

    return FileResult(
      path: file.path ?? file.uri.toString(),
      name: file.name,
      content: content,
      modifiedAt: null,
    );
  }

  /// Prompts the user to save [content] to a public file and returns the saved
  /// file's URI, or null if the user cancelled.
  Future<String?> saveTextFile({
    required String content,
    String suggestedName = 'note.txt',
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: suggestedName,
      bytes: utf8.encode(content),
      mimeType: 'text/plain',
    );
    return uri?.toString();
  }

  Future<String?> _readPlatformFile(PlatformFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }
}
