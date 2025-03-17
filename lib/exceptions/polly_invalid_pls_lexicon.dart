import 'dart:io';

class PollyInvalidPlsLexicon implements Exception {
  final String message;
  final File _file;

  PollyInvalidPlsLexicon(this.message, File file) : _file = file;

  @override
  String toString() {
    return message;
  }

  File get file => _file;
}
