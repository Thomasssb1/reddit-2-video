class SubprocessException implements Exception {
  final String message;
  final String? detail;
  final String executable;
  final List<String> arguments;
  final int? exitCode;
  final String? stdout;
  final String? stderr;

  SubprocessException({
    required this.message,
    required this.executable,
    required this.arguments,
    this.exitCode,
    this.stdout,
    this.stderr,
    String? detail,
  }) : detail = _buildDetail(detail, stdout, stderr);

  String? get errorDetail => _normalize(detail);

  static String? _buildDetail(
    String? detail,
    String? stdout,
    String? stderr,
  ) {
    final sections = <String>[];
    final normalizedDetail = _normalize(detail);
    final normalizedStderr = _normalize(stderr);
    final normalizedStdout = _normalize(stdout);

    if (normalizedDetail != null) {
      sections.add(normalizedDetail);
    }
    if (normalizedStderr != null) {
      sections.add(normalizedStderr);
    }
    if (normalizedStdout != null) {
      sections.add(normalizedStdout);
    }

    if (sections.isEmpty) {
      return null;
    }
    return sections.join('\n\n');
  }

  static String? _normalize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trimRight();
  }

  @override
  String toString() => message;
}
