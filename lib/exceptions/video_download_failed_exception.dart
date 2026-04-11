import 'package:reddit_2_video/exceptions/subprocess_exception.dart';

class VideoDownloadFailedException extends SubprocessException {
  final Uri url;

  VideoDownloadFailedException({
    required super.message,
    required this.url,
    required super.executable,
    required super.arguments,
    super.exitCode,
    super.stdout,
    super.stderr,
    super.detail,
  });
}
