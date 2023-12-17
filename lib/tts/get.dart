import 'dart:io';
import 'package:reddit_2_video/utils/prepath.dart';

List<String> getTTSFiles(String id) {
  List<String> files = Directory("$prePath/.temp/$id/tts/")
      .listSync()
      .map((e) => e.path)
      .toList();
  files.sort((a, b) => a.compareTo(b));
  return files;
}
