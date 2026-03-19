import 'dart:io';

Future<void> createDummyVideo(String path) async {
  // Generate a 1-second blank video using ffmpeg
  final process = await Process.run('ffmpeg', [
    '-f', 'lavfi',
    '-i', 'color=c=black:s=128x128:d=1',
    '-c:v', 'libx264',
    '-y',
    path,
  ]);
  
  if (process.exitCode != 0) {
    // Fallback to a simple file if ffmpeg is missing or fails (though tests will likely fail)
    File(path).writeAsStringSync("dummy content");
  }
}
