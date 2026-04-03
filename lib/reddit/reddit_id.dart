class RedditId {
  final String _id;
  final String _subredditId;

  const RedditId(String id, String subredditId)
      : _id = id,
        _subredditId = subredditId;

  String get postId => _id;
  String get subredditId => _subredditId;
  String get id => "$_id-$_subredditId";

  @override
  String toString() {
    return id;
  }

  @override
  bool operator ==(Object other) {
    if (other is! RedditId) {
      return false;
    }
    return other.id == id;
  }

  @override
  int get hashCode => Object.hashAll([_id, _subredditId]);
}
