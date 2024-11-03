class BackgroundVideoCuttingException implements Exception {
  final String message;
  final Uri url;
  final Duration duration;

  BackgroundVideoCuttingException(
      {required this.message, required this.url, required this.duration});

  @override
  String toString() {
    return message;
  }
}
