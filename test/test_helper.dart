import 'dart:io';

import 'package:reddit_2_video/utils/subprocess.dart';

String resolveExecutable(String executable) {
  if (File(executable).existsSync()) {
    return executable;
  }

  for (final prefix in const ['/opt/homebrew/bin', '/usr/local/bin']) {
    final candidate = '$prefix/$executable';
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  return executable;
}

void useRealSubprocesses() {
  Subprocess.setStartForTest((executable, arguments,
      {workingDirectory,
      environment,
      includeParentEnvironment = true,
      runInShell = false,
      mode = ProcessStartMode.normal}) {
    return Process.start(
      resolveExecutable(executable),
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  });
}

Future<void> createDummyVideo(String path,
    {int seconds = 1, String size = '128x128'}) async {
  // Generate a blank video using ffmpeg for media-based tests.
  final process = await Process.run(resolveExecutable('ffmpeg'), [
    '-f',
    'lavfi',
    '-i',
    'color=c=black:s=$size:d=$seconds',
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

Future<void> createDummyAudio(String path, {int seconds = 1}) async {
  final process = await Process.run(resolveExecutable('ffmpeg'), [
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=880:duration=$seconds',
    '-q:a',
    '9',
    '-acodec',
    'libmp3lame',
    '-y',
    path,
  ]);

  if (process.exitCode != 0) {
    throw Exception('Failed to create test audio: ${process.stderr}');
  }
}
