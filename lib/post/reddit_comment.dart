class RedditComment {
  final String _author;
  final String _body;
  final DateTime _created;
  final int _upvotes;
  final String? _collapsedReason;

  RedditComment({
    required String author,
    required String body,
    required DateTime created,
    required int upvotes,
    required String? collapsedReason,
  })  : _author = author,
        _body = body,
        _created = created,
        _upvotes = upvotes,
        _collapsedReason = collapsedReason;

  bool isRemoved() {
    return _body == "[removed]" || _collapsedReason == "DELETED";
  }

  String get author => _author;
  String get body => _body;
  DateTime get created => _created;
  int get upvotes => _upvotes;
}
