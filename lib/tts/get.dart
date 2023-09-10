import 'dart:io';
import 'package:reddit_2_video/utils/prepath.dart';

List<String> getTTSFiles(String id, [bool full = true]) => List.generate(
        getTTSCount(id),
        (index) => ["${full ? '${prePath}/.temp/tts/' : ''}tts-$index.mp3"],
        growable: false)
    .expand((e) => e)
    .toList();

int getTTSCount(String id) =>
    Directory("$prePath/.temp/$id/tts").listSync().length;
