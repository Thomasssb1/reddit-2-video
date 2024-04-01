import 'dart:io';
import 'package:reddit_2_video/utils/globals.dart' show prePath;

List<String> getTTSFiles(
  String id,
) {
  List<String> files = Directory("$prePath/.temp/$id/tts/")
      .listSync()
      .map((e) => e.path)
      .toList();
  files.sort((a, b) => getTTSWeight(a).compareTo(getTTSWeight(b)));
  return files;
}

int getTTSWeight(String filename) {
  // follows tts-i-j.mp3 format
  List<String> filePart =
      Uri.file(filename).pathSegments.last.replaceAll(".mp3", "").split("-");
  return int.parse(filePart[1] + filePart[2]);
}
