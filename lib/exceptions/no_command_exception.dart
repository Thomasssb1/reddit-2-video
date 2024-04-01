class NoCommandException implements Exception {
  final String message;

  NoCommandException(this.message);

  @override
  String toString() {
    return message;
  }
}
