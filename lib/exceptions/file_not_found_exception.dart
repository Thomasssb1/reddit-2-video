import 'dart:io';

class FileNotFoundException implements Exception {
  final String message;
  final File _file;

  FileNotFoundException(this.message, File file) : _file = file;

  @override
  String toString() {
    return message;
  }

  File get file => _file;
}
