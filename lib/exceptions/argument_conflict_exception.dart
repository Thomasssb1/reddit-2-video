class ArgumentConflictException implements Exception {
  final String message;
  final String _argument1;
  final String _argument2;

  ArgumentConflictException(this.message, String argument1, String argument2)
      : _argument1 = argument1,
        _argument2 = argument2;

  String get argument1 => _argument1;
  String get argument2 => _argument2;

  @override
  String toString() {
    return message;
  }
}
