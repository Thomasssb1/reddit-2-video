import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';

class SubtitleLineData {
  String text;
  final Duration end;
  final Duration start;
  final bool finalWord;
  final int segmentID;

  SubtitleLineData({
    required this.text,
    required this.end,
    required this.start,
    required this.finalWord,
    required this.segmentID,
  });

  bool isFinalSegment(int segmentCount) {
    return segmentCount == segmentID;
  }

  bool get isFinalWord => finalWord;

  @override
  String toString() {
    return text;
  }
}
