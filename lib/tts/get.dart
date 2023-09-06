import 'dart:io';
import 'package:reddit_2_video/utils/prepath.dart';

List<String> getTTSFiles([bool full = true]) => List.generate(getTTSCount(),
        (index) => ["${full ? '${prePath}/.temp/tts/' : ''}tts-$index.mp3"],
        growable: false)
    .expand((e) => e)
    .toList();

int getTTSCount() => Directory("$prePath/.temp/tts").listSync().length;
