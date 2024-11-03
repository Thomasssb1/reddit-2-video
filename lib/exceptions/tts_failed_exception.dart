class TTSFailedException implements Exception {
  final String message;
  final String id;
  final String text;

  const TTSFailedException(
      {required this.message, required this.id, required this.text});

  @override
  String toString() {
    return message;
  }
}
