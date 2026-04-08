import 'package:reddit_2_video/exceptions/subprocess_exception.dart';

class TTSFailedException extends SubprocessException {
  final String id;
  final String text;

  TTSFailedException({
    required super.message,
    required this.id,
    required this.text,
    required super.executable,
    required super.arguments,
    super.exitCode,
    super.stdout,
    super.stderr,
    super.detail,
  });
}
