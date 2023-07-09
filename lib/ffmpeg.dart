import 'dart:io';
import 'dart:convert';
import 'utils.dart';
import 'package:path/path.dart' as p;

Future<int> generateSubtitles(bool offlineTTS, List<dynamic> postData) async {
  /// [Remember] ffmpeg uses `HGGBBRR`
  String animation(colour) =>
      r"{\an5\1c&H000000&\t(0, 150, \1c&" +
      colour +
      r"& \frz0\frscx0\frscy0\t(0, 150, \fscx100, \fscy100))}{\fad(150,150)}";

  final fileForTTS = File("./.temp/comments.json");
  final sinkTTS = fileForTTS.openWrite();

  Map tempJson = {"text": []};

  tempJson["settings"] = {"offline": offlineTTS, "accent": "com.mx"};
  tempJson["text"].add(postData[0]['post']['title']);

  final defaultASS = File("./defaults/default.ass");
  final contents = await defaultASS.readAsString();

  final fileForComments = File("./.temp/comments.ass");
  final sinkComments = fileForComments.openWrite();
  sinkComments.write("$contents\n");

  final List<String> splitTitle = splitComments(postData[0]['post']['title']);
  String startTime = "0:00:00.00";
  for (final text in splitTitle) {
    final newTime = lengthCalculation(text, startTime);
    sinkComments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,${animation('H0000FF')}$text\n");

    startTime = newTime;
  }
  for (final comment in postData[1]['comments']) {
    List<String> splitComment = splitComments(comment['body']);
    tempJson["text"].add(comment['body']);
    for (final comment in splitComment) {
      final newTime = lengthCalculation(comment, startTime);
      sinkComments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,${animation('HFFFFFF')}$comment\n");
      startTime = newTime;
    }
  }

  sinkTTS.write(json.encode(tempJson));
  sinkComments.close();

  int prevMinutes = int.parse(startTime[2] + startTime[3]);
  int prevSeconds = int.parse(startTime[5] + startTime[6]);
  int prevMilliseconds = int.parse(startTime.substring(8)) * 10;

  return (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000));
  //return errors
}

Future<List<String>> generateCommand(String output, int end, int fps, String fileType, List<String> music) async {
  List<String> command = ["-i", "./defaults/video1.mp4"];
  List<String> inputStreams = [];

  final tts = Directory('./.temp/tts').list();
  int i = 1;
  await for (final value in tts) {
    command.addAll(["-i", value.path]);
    inputStreams.add("[$i:a]");
    i++;
  }

  if (output.endsWith('/')) {
    print("No filename provided - using a default filename.");
    output += "final";
  } else {
    String fileName = p.basename(output);
    String fileExtension = fileName.split(RegExp(r'^.*(?=(\.[0-9a-z]+$))')).last.replaceFirst('.', '');
    output = output.replaceAll(".$fileExtension", '');
    if (fileExtension != fileType) {
      print(
          "\nOutput file extension does not match the requested filetype, overriding the filetype to be the same as the value of the -file-type flag ($fileType).\n If you do not want this to happen, then change the value of the -file-type flag to match the desired output type.\n");
    }
  }

  command.addAll([
    if (music.isNotEmpty) ...['-i', music[0]],
    '-map',
    '0:v',
    '-map',
    '[final_a]',
    '-ss',
    '0ms',
    '-to',
    '${end + 100}ms',
    '-filter_complex',
    '${inputStreams.join(' ')} concat=n=${inputStreams.length}:v=0:a=1${(music.isNotEmpty) ? "[0a];[${inputStreams.length + 1}:a]volume=${double.tryParse(music[1]) ?? 1}[1a];[0a][1a]amerge" : ""}[final_a], crop=585:1080, subtitles=.temp/comments.ass, fps=$fps',
    '$output.$fileType'
  ]);

  return command;
}
