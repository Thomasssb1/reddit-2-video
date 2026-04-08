import 'dart:io';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:path/path.dart' as p;
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/progress.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';

Future<List<File>> splitVideo(
    String outputFilePath, String fileExtension, int count,
    {bool verbose = false}) async {
  final progressTask = generationProgress.createTask(
    title: 'Splitting YouTube shorts',
    detail: outputFilePath,
    section: LogSection.split,
    totalUnits: 1,
    weight: 4,
  );
  String dir = p.dirname(outputFilePath);
  String baseName = p.basenameWithoutExtension(outputFilePath);
  final segmentBaseName = count == 0 ? baseName : '$baseName-';

  List<String> commandArgs = [
    '-i',
    outputFilePath,
    '-c',
    'copy',
    '-map',
    '0',
    '-reset_timestamps',
    '1',
    '-segment_time',
    '00:00:55',
    '-f',
    'segment',
    p.join(dir, '$segmentBaseName%03d.$fileExtension'),
  ];

  final result = await Subprocess.exec('ffmpeg', commandArgs,
      verbose: verbose, section: LogSection.split);

  int code = result.exitCode;
  if (code != 0) {
    generationProgress.completeTask(progressTask, detail: 'Split failed');
    throw FFmpegCommandException(
      message:
          "Something went wrong when splitting the video into segments for youtube shorts. Error code $code",
      command: commandArgs,
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }

  // Find the generated segments
  final segmentPattern = RegExp(
    '^${RegExp.escape(segmentBaseName)}\\d{3}\\.${RegExp.escape(fileExtension)}\$',
  );

  final segments = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((file) => segmentPattern.hasMatch(p.basename(file.path)))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  generationProgress.completeTask(progressTask,
      detail: 'Generated ${segments.length} short segments');
  return segments;
}
