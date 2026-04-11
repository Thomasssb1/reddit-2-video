class InvalidPostUrlException implements Exception {
  final String message;
  final String _url;

  InvalidPostUrlException(this.message, String url) : _url = url;

  @override
  String toString() {
    return '$message, url: $url';
  }

  String get url => _url;
}
