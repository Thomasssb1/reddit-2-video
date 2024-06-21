import 'dart:io';
import 'package:mp3_info/mp3_info.dart';
import 'package:reddit_2_video/subtitles/subtitle_config.dart';
import 'package:reddit_2_video/subtitles/subtitle_line_data.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:reddit_2_video/config/voice.dart';

class Subtitle {
  final int maxCharacterCount = 30;

  final String text;
  final Voice voice;
  final SubstationAlphaSubtitleColor color;
  final SubtitleConfig config;

  const Subtitle({
    required this.text,
    required this.voice,
    required this.color,
    required this.config,
  });

  void generate(
    File assFile,
    Subtitle prevSubtitle,
  ) {
    for (final segment in config.segments) {
      List<SubtitleLineData> lineData = [];
      num characterCount = 0;
      if (segment['words'][0]['text'] != 'you') {
        var words = segment['words'];
        for (int i = 0; i < words.length; i++) {
          if (characterCount + words[i]['text'].length > maxCharacterCount) {
            _karaokeEffect(
                lineData, assFile, prevSubtitle, config.segments.length);
            lineData = [];
            characterCount = 0;
          }
          lineData.add(SubtitleLineData(
            text: words[i]['text'],
            end: (words[i]['end'] * 1000).toInt(),
            start: (words[i]['start'] * 1000).toInt(),
            finalWord: (i == words.length - 1),
            segmentID: segment['id'],
          ));
          characterCount += words[i]['text'].length;
        }
        if (lineData.isNotEmpty) {
          _karaokeEffect(
              lineData, assFile, prevSubtitle, config.segments.length);
        }
      }
    }
  }

  Subtitle.none()
      : text = '',
        voice = Voice.brian,
        color = SubstationAlphaSubtitleColor("#FFFFFF"),
        config = SubtitleConfig.none();

  String _getNewTime(Duration time) =>
      "${time.inHours}:${time.inMinutes.remainder(60).toString().padLeft(2, '0')}:${time.inSeconds.remainder(60).toString().padLeft(2, '0')}.${time.inMilliseconds.remainder(1000).toString().padLeft(3, '0').substring(0, 2)}";

  void _karaokeEffect(List<SubtitleLineData> lineData, File assFile,
      Subtitle prevSubtitle, int segmentCount) {
    IOSink sink = assFile.openWrite();
    for (int i = 0; i < lineData.length; i++) {
      String start = _getNewTime(Duration(
          milliseconds:
              lineData[i].start + prevSubtitle.duration.inMilliseconds));

      String end = _getNewTime(
          lineData[i].isFinalWord && lineData[i].isFinalSegment(segmentCount)
              ? duration
              : Duration(
                  milliseconds:
                      lineData[i].end + prevSubtitle.duration.inMilliseconds));

      List<SubtitleLineData> words = lineData.sublist(0, i + 1);
      SubtitleLineData word =
          words.firstWhere((e) => e.text == lineData[i].text);
      word.addHighlight();

      sink.writeln(
          "Dialogue: 0,$start,$end,Default,,0,0,0,,{\\c&$color}{\\an5\\frz0}${words.cast<String>().join(' ')}");
    }
  }

  Duration get duration => MP3Processor.fromFile(config.tts).duration;
}
