import 'dart:io';

class OutputFileExistsException implements Exception {
  final String message;
  final File file;

  const OutputFileExistsException({
    required this.message,
    required this.file,
  });

  @override
  String toString() {
    return message;
  }
}
