class RedditApiException implements Exception {
  final String message;
  final int statusCode;

  RedditApiException({required this.message, required this.statusCode});

  @override
  String toString() {
    return '$message, status code: $statusCode';
  }
}
