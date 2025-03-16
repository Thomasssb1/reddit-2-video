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
  SubstationAlphaSubtitleColor color;
  SubstationAlphaSubtitleColor highlightColour =
      SubstationAlphaSubtitleColor("#FFFF00");
  final SubtitleConfig config;

  Subtitle({
    required this.text,
    required this.voice,
    required this.color,
    required this.config,
  });

  Future<void> generate(
    File assFile,
    Duration prevDuration,
  ) async {
    for (final segment in config.segments) {
      List<SubtitleLineData> lineData = [];
      num characterCount = 0;
      if (segment['words'][0]['text'] != 'you') {
        var words = segment['words'];
        for (int i = 0; i < words.length; i++) {
          if (characterCount + words[i]['text'].length > maxCharacterCount) {
            await _karaokeEffect(
                lineData, assFile, prevDuration, config.segments.length);
            lineData = [];
            characterCount = 0;
          }
          lineData.add(SubtitleLineData(
            text: words[i]['text'],
            end: Duration(milliseconds: (words[i]['end'] * 1000).toInt()),
            start: Duration(milliseconds: (words[i]['start'] * 1000).toInt()),
            finalWord: (i == words.length - 1),
            segmentID: segment['id'],
          ));
          characterCount += words[i]['text'].length;
        }
        if (lineData.isNotEmpty) {
          await _karaokeEffect(
              lineData, assFile, prevDuration, config.segments.length);
        }
      }
    }
  }

  Subtitle.none()
      : text = '',
        voice = Voice.standard(),
        color = SubstationAlphaSubtitleColor("#FFFFFF"),
        config = SubtitleConfig.none();

  String _getNewTime(Duration time) =>
      "${time.inHours}:${time.inMinutes.remainder(60).toString().padLeft(2, '0')}:${time.inSeconds.remainder(60).toString().padLeft(2, '0')}.${time.inMilliseconds.remainder(1000).toString().padLeft(3, '0').substring(0, 2)}";

  Future<void> _karaokeEffect(List<SubtitleLineData> lineData, File assFile,
      Duration prevDuration, int segmentCount) async {
    IOSink sink = assFile.openWrite(mode: FileMode.append);
    for (int i = 0; i < lineData.length; i++) {
      String start = _getNewTime(lineData[i].start + prevDuration);

      String end = _getNewTime(
          lineData[i].isFinalWord && lineData[i].isFinalSegment(segmentCount)
              ? duration
              : lineData[i].end + prevDuration);

      List<SubtitleLineData> words = lineData.sublist(0, i + 1);
      SubtitleLineData word =
          words.firstWhere((e) => e.text == lineData[i].text);
      addHighlight(word);

      sink.writeln(
          "Dialogue: 0,$start,$end,Default,,0,0,0,,{\\c&$color}{\\an5\\frz0}${words.map((e) => e.toString()).join(' ')}");

      removeHighlight(word);
    }
    await sink.close();
  }

  Duration get duration => MP3Processor.fromFile(config.tts).duration;

  void addHighlight(SubtitleLineData lineData) {
    lineData.text = "{\\c&$highlightColour}${lineData.text}";
  }

  void removeHighlight(SubtitleLineData lineData) {
    int index = "{\\c&$highlightColour}".length;
    lineData.text = lineData.text.substring(index);
  }

  void updateTitleColours(SubstationAlphaSubtitleColor titleColour) {
    highlightColour = SubstationAlphaSubtitleColor("#FFFFFF");
    color = titleColour;
  }
}
