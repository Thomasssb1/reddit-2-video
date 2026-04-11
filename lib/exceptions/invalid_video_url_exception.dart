class InvalidVideoUrl implements Exception {
  final String message;
  final Uri _url;

  InvalidVideoUrl(this.message, Uri url) : _url = url;

  @override
  String toString() {
    return '$message, url: $url';
  }

  Uri get url => _url;
}
