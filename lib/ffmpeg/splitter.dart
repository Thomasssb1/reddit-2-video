import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';
import 'package:path/path.dart' as p;

splitVideo(String output, String fileType) async {
  String fileName = p.basename(output);
  String fileExtension = fileName
      .split(RegExp(r'^.*(?=(\.[0-9a-z]+$))'))
      .last
      .replaceFirst('.', '');
  // remove the file extension from the output path
  output = output.replaceAll(".$fileExtension", '');

  int code = await runCommand(
      'ffmpeg',
      [
        '-i',
        "$output.$fileType",
        '-c',
        'copy',
        '-map',
        '0',
        '-segment_time',
        '00:00:55',
        '-f',
        'segment',
        '$output%03d.mp4',
      ],
      true);
  if (code == 0) {
    printSuccess("Successfully split the video into ~1min segments.");
  } else {
    printError(
        "Something went wrong when splitting the video into segments for youtube shorts. Error code $code");
  }
}
