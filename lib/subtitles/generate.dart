import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/tts/get.dart';
import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/subtitles/time.dart';

/// [Remember] ffmpeg uses `HBBGGRR`
String animation(colour) => r"{\an5}";
//r"{\an5\1c&H000000&\t(0, 150, \1c&" +
//colour +
//r"& \frz0\frscx0\frscy0\t(0, 150, \fscx100, \fscy100))}{\fad(150,150)}";

Future<Duration> generateSubtitles(String titleColour, bool alternateColour, bool aws, String id, bool addDelay) async {
  final defaultASS = await File("$prePath\\defaults\\default.ass").readAsString();
  final newASS = File("$prePath\\.temp\\$id\\comments.ass");
  final sinkComments = newASS.openWrite();
  sinkComments.writeln(defaultASS);

  final config = File("$prePath\\defaults\\config.json");
  final json = jsonDecode(config.readAsStringSync());
  List<dynamic> colours = json['colours'];
  int currentColour = 0;
  String bodyColour = alternateColour ? colours[currentColour] : 'HFFFFFF';

  int maxCharacterCount = 30;

  Duration time = Duration.zero;
  Duration prevFileTime = Duration.zero;
  List<String> ttsFiles = getTTSFiles(id, false);

  // remove time for animation to account for it

  for (int i = 0; i < ttsFiles.length; i++) {
    String jsonData = await File("$prePath\\.temp\\$id\\config\\tts-$i.mp3.words.json").readAsString();
    var json = jsonDecode(jsonData);
    for (final segment in json['segments']) {
      List<dynamic> wordSet = [];
      num characterCount = 0;
      for (final word in segment['words']) {
        if (characterCount + word['text'].length > maxCharacterCount) {
          karaokeEffect(wordSet, sinkComments, prevFileTime, i == 0, bodyColour, titleColour);
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
        karaokeEffect(wordSet, sinkComments, prevFileTime, i == 0, bodyColour, titleColour);
      }
    }
    prevFileTime = (Duration(milliseconds: time.inMilliseconds + (addDelay ? 1000 : 0)));
    currentColour = ++currentColour % colours.length;
  }
  sinkComments.close();
  return time;
}

karaokeEffect(List<dynamic> line, dynamic sinkComments, Duration prevFileTime, bool isTitle, String bodyColour,
    String titleColour) {
  for (int i = 0; i < line.length; i++) {
    sinkComments.writeln(
        "Dialogue: 0,${getNewTime(Duration(milliseconds: line[i]['start'] + prevFileTime.inMilliseconds))},${getNewTime(Duration(milliseconds: line[i]['end'] + prevFileTime.inMilliseconds))},Default,,0,0,0,," +
            (isTitle ? r"{\c&" + "$titleColour}" : r"{\c&" + "$bodyColour}") +
            r"{\an5\frz0}" +
            line
                .sublist(0, i + 1)
                .map((e) => (line.indexOf(e) == i)
                    ? isTitle
                        ? r"{\c&HFFFFFF}" + e['text']
                        : r"{\c&H00FFFF}" + e['text']
                    : e['text'])
                .join(' '));
  }
}
