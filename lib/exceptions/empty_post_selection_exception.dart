class EmptyPostSelectionException implements Exception {
  final String message;
  const EmptyPostSelectionException({required this.message});

  @override
  String toString() {
    return message;
  }
}
