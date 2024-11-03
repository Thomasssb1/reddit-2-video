class FFmpegCommandException implements Exception {
  final String message;
  final List<String> command;

  FFmpegCommandException({required this.message, required this.command});

  @override
  String toString() {
    return message;
  }
}
