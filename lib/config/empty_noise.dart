import 'package:reddit_2_video/config/config_item.dart';
import 'package:mp3_info/mp3_info.dart';
import 'dart:io';

class EmptyNoise extends ConfigItem {
  static Duration Function(File file) _durationReader =
      (file) => MP3Processor.fromFile(file).duration;

  int? position;
  EmptyNoise()
      : super(
          path: 'defaults/silence.mp3',
        );

  Duration get duration => _durationReader(path);

  static void setDurationReaderForTest(Duration Function(File file) reader) {
    _durationReader = reader;
  }

  static void resetForTest() {
    _durationReader = (file) => MP3Processor.fromFile(file).duration;
  }
}
