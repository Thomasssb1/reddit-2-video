import 'dart:io';

Future<void> createDummyVideo(String path, {int seconds = 1}) async {
  // Generate a blank video using ffmpeg for media-based tests.
  final process = await Process.run('ffmpeg', [
    '-f',
    'lavfi',
    '-i',
    'color=c=black:s=128x128:d=$seconds',
    '-c:v',
    'libx264',
    '-pix_fmt',
    'yuv420p',
    '-y',
    path,
  ]);

  if (process.exitCode != 0) {
    throw Exception('Failed to create test video: ${process.stderr}');
  }
}
