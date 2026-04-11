class ArgumentMissingException implements Exception {
  final String message;

  ArgumentMissingException(this.message);

  @override
  String toString() {
    return message;
  }
}
