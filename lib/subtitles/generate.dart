import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/subtitles/time.dart';

/// [Remember] ffmpeg uses `HBBGGRR`
String animation(colour) => r"{\an5}";
//r"{\an5\1c&H000000&\t(0, 150, \1c&" +
//colour +
//r"& \frz0\frscx0\frscy0\t(0, 150, \fscx100, \fscy100))}{\fad(150,150)}";

Future<Duration> generateSubtitles(String id, String ttsID, bool alternateColour, bool isTitle, bool addDelay,
    String currentColour, Duration prevFileTime, IOSink sinkComments) async {
  final String highlightColour = alternateColour | isTitle ? 'HFFFFFF' : 'H00FFFF';
  final int maxCharacterCount = 30;

  Duration time = Duration.zero;

  String jsonData = await File("$prePath\\.temp\\$id\\config\\tts-$ttsID.mp3.words.json").readAsString();
  var json = jsonDecode(jsonData);
  for (final segment in json['segments']) {
    List<dynamic> wordSet = [];
    num characterCount = 0;
    // whisper_timestamped sometimes hallucinates you
    if (segment['words'][0]['text'] != ['you']) {
      for (final word in segment['words']) {
        if (characterCount + word['text'].length > maxCharacterCount) {
          karaokeEffect(wordSet, sinkComments, prevFileTime, highlightColour, currentColour);
          wordSet = [
            {"text": word['text'], "end": (word['end'] * 1000).toInt(), "start": (word['start'] * 1000).toInt()}
          ];
          characterCount = 0;
        } else {
          wordSet.add(
              {"text": word['text'], "end": (word['end'] * 1000).toInt(), "start": (word['start'] * 1000).toInt()});
          characterCount += word['text'].length;
        }
        time = Duration(milliseconds: (word['end'] * 1000).toInt() + prevFileTime.inMilliseconds);
      }
      if (wordSet.isNotEmpty) {
        karaokeEffect(wordSet, sinkComments, prevFileTime, highlightColour, currentColour);
      }
    }
  }
  return time;
}

karaokeEffect(
    List<dynamic> line, IOSink sinkComments, Duration prevFileTime, String highlightColour, String textColour) {
  for (int i = 0; i < line.length; i++) {
    sinkComments.writeln(
        "Dialogue: 0,${getNewTime(Duration(milliseconds: line[i]['start'] + prevFileTime.inMilliseconds))},${getNewTime(Duration(milliseconds: line[i]['end'] + prevFileTime.inMilliseconds))},Default,,0,0,0,," +
            r"{\c&" +
            "$textColour}" +
            r"{\an5\frz0}" +
            line
                .sublist(0, i + 1)
                .map((e) => (line.indexOf(e) == i) ? r"{\c&" + "$highlightColour}" + e['text'] : e['text'])
                .join(' '));
  }
}
