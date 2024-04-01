class ArgumentNotImplementedException implements Exception {
  final String message;

  ArgumentNotImplementedException(this.message);

  @override
  String toString() {
    return message;
  }
}
