import 'dart:io';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:path/path.dart' as p;

Future<List<File>> splitVideo(
    String outputFilePath, String fileExtension, int count) async {
  String dir = p.dirname(outputFilePath);
  String baseName = p.basenameWithoutExtension(outputFilePath);

  List<String> commandArgs = [
    '-i',
    outputFilePath,
    '-c',
    'copy',
    '-map',
    '0',
    '-segment_time',
    '00:00:55',
    '-f',
    'segment',
    p.join(dir, '$baseName${count == 0 ? "" : count}%03d.$fileExtension'),
  ];

  var process = await Process.start('ffmpeg', commandArgs,
      mode: ProcessStartMode.inheritStdio);

  int code = await process.exitCode;
  if (code != 0) {
    throw FFmpegCommandException(
        message:
            "Something went wrong when splitting the video into segments for youtube shorts. Error code $code",
        command: commandArgs);
  }

  // Find the generated segments
  final segmentPattern =
      RegExp('^' + RegExp.escape(baseName) + r'\d+\.' + RegExp.escape(fileExtension) + r'$');
  return Directory(dir)
      .listSync()
      .whereType<File>()
      .where((file) => segmentPattern.hasMatch(p.basename(file.path)))
      .toList();
}
