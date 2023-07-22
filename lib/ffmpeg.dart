import 'dart:io';
import 'dart:convert';
import 'utils.dart';
import 'package:path/path.dart' as p;

Future<int> generateSubtitles(bool nttsActive, List<dynamic> postData) async {
  /// [Remember] ffmpeg uses `HGGBBRR`
  String animation(colour) =>
      r"{\an5\1c&H000000&\t(0, 150, \1c&" +
      colour +
      r"& \frz0\frscx0\frscy0\t(0, 150, \fscx100, \fscy100))}{\fad(150,150)}";

  Map tempJson = {"text": []};

  tempJson["settings"] = {"ntts": nttsActive, "accent": "com.mx"};

  final defaultASS = File("./defaults/default.ass");
  final contents = await defaultASS.readAsString();

  final fileForComments = File("./.temp/comments.ass");
  final sinkComments = fileForComments.openWrite();
  sinkComments.write("$contents\n");

  String startTime = "0:00:00.00";
  int counter = 1;
  for (final post in postData) {
    for (int i = 0; i < post.length; i++) {
      if (post[i].isNotEmpty) {
        tempJson["text"].add(post[i].replaceAll('"', r'\"'));
        final List<String> splitInfo = splitComments(post[i].replaceAll("\n", " "));
        for (final text in splitInfo) {
          final duration = await generateTTS(text, counter, nttsActive, startTime);
          final newTime = lengthCalculation(duration, startTime);

          if (i == 0) {
            sinkComments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,${animation('H0000FF')}$text\n");
          } else {
            sinkComments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,${animation('HFFFFFF')}$text\n");
          }
          startTime = newTime;
          counter++;
        }
      }
    }
  }

  sinkComments.close();

  int prevMinutes = int.parse(startTime[2] + startTime[3]);
  int prevSeconds = int.parse(startTime[5] + startTime[6]);
  int prevMilliseconds = int.parse(startTime.substring(8)) * 10;

  return (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000));
  //return errors
}

Future<List<String>> generateCommand(String output, int end, int fps, String fileType, List<String> music, String video,
    bool override, int ttsCount) async {
  List<String> command = ["-i", video];

  command.addAll(List.generate(ttsCount, (index) => ["-i", "./.temp/tts/tts-$index.wav"], growable: false)
      .expand((e) => e)
      .toList());

  List<String> inputStreams = List.generate(ttsCount, (index) => "[${index + 1}:a]");

  if (output.endsWith('/')) {
    print("No filename provided - using a default filename.");
    output += "final";
  } else {
    String fileName = p.basename(output);
    String fileExtension = fileName.split(RegExp(r'^.*(?=(\.[0-9a-z]+$))')).last.replaceFirst('.', '');
    output = output.replaceAll(".$fileExtension", '');
    if (fileExtension != fileType) {
      printWarning(
          "\nOutput file extension does not match the requested filetype, overriding the filetype to be the same as the value of the --file-type option ($fileType).\n If you do not want this to happen, then change the value of the --file-type flag to match the desired output type.\n");
    }
  }

  command.addAll([
    if (music.isNotEmpty) ...['-i', music[0]],
    if (override) '-y',
    '-map',
    '0:v',
    '-map',
    '[final_a]',
    '-ss',
    '0ms',
    '-to',
    '${end + 100}ms',
    '-filter_complex',
    '${inputStreams.join(' ')} concat=n=$ttsCount:v=0:a=1${(music.isNotEmpty) ? "[0a];[${ttsCount + 1}:a]volume=${double.tryParse(music[1]) ?? 1}[1a];[0a][1a]amerge" : ""}[final_a], crop=585:1080, subtitles=.temp/comments.ass, fps=$fps',
    '$output.$fileType'
  ]);

  return command;
}
