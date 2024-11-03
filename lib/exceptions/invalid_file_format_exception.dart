import 'dart:io';

class InvalidFileFormatException implements Exception {
  final String message;
  final File _file;

  InvalidFileFormatException(this.message, File file) : _file = file;

  @override
  String toString() {
    return '$message';
  }

  File get file => _file;
}
