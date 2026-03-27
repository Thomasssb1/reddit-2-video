class MaxLengthExceededException implements Exception {
  final String message;
  final Duration maxLength;
  final Duration actualLength;

  MaxLengthExceededException({
    required this.message,
    required this.maxLength,
    required this.actualLength,
  });

  @override
  String toString() {
    return message;
  }
}
