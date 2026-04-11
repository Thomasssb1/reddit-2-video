import 'package:reddit_2_video/exceptions/subprocess_exception.dart';

class FFmpegCommandException extends SubprocessException {
  final List<String> command;

  FFmpegCommandException({
    required super.message,
    required this.command,
    super.exitCode,
    super.stdout,
    super.stderr,
    super.detail,
  }) : super(
          executable: 'ffmpeg',
          arguments: command,
        );
}
