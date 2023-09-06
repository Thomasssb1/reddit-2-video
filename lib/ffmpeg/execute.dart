import 'package:reddit_2_video/utils/prettify.dart';
import 'dart:io';
import 'dart:convert';

Future<bool> runFFMPEGCommand(List<String> command, String path) async {
  var process = await Process.start('ffmpeg', command);
  process.stderr.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });
  int code = await process.exitCode;
  //await clearTemp();
  if (code == 0) {
    printSuccess(
        "Final video has successfully generated.\nThe video has been created at $path.");
    return true;
  } else {
    printError(
        "Something went wrong when generating the video. Please try again.\nIf the problem persists, post it as an issue on github.\nhttps://github.com/Thomasssb1/reddit-2-video/issues");
    return false;
  }
}
