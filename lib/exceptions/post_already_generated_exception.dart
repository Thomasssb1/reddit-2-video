class PostAlreadyGeneratedException implements Exception {
  final String message;
  final String help;

  const PostAlreadyGeneratedException({
    required this.message,
    String? help,
  }) : help = help ?? "";

  @override
  String toString() {
    return message;
  }
}
