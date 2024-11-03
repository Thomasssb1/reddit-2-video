class VideoDownloadFailedException implements Exception {
  final String message;
  final Uri url;

  const VideoDownloadFailedException(
      {required this.message, required this.url});

  @override
  String toString() {
    return message;
  }
}
