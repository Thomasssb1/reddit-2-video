class PostsExhaustedException implements Exception {
  final String message;

  const PostsExhaustedException({
    required this.message,
  });

  @override
  String toString() {
    return message;
  }
}
