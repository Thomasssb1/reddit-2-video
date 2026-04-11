import 'package:reddit_2_video/exceptions/subprocess_exception.dart';

class BackgroundVideoCuttingException extends SubprocessException {
  final String url;
  final Duration duration;

  BackgroundVideoCuttingException({
    required super.message,
    required this.url,
    required this.duration,
    required super.executable,
    required super.arguments,
    super.exitCode,
    super.stdout,
    super.stderr,
    super.detail,
  });
}
