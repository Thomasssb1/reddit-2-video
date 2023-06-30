import 'dart:io';
import 'dart:convert';
import 'utils.dart';

Future<int> generateSubtitles(bool offlineTTS, List<dynamic> postData) async {
  String animation =
      r"{\an5\1c&H000000&\t(0, 150, \1c&HFFFFFF& \frz0\frscx0\frscy0\t(0, 150, \fscx100, \fscy100)}{\fad(150,150)}";

  final file_for_tts = File("./.temp/comments.json");
  final sink_tts = file_for_tts.openWrite();

  Map tempJson = {"text": []};

  tempJson["settings"] = {"offline": offlineTTS, "accent": "com.mx"};
  tempJson["text"].add(postData[0]['post']['title']);

  final default_ass = File("./defaults/default.ass");
  final contents = await default_ass.readAsString();

  final file_for_comments = File("./.temp/comments.ass");
  final sink_comments = file_for_comments.openWrite();
  sink_comments.write("$contents\n");

  final List<String> splitTitle = splitComments(postData[0]['post']['title']);
  String startTime = "0:00:00.00";
  for (final text in splitTitle) {
    final newTime = lengthCalculation(text, startTime);
    final newDialog = sink_comments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,$animation$text\n");

    startTime = newTime;
  }
  for (final comment in postData[1]['comments']) {
    List<String> splitComment = splitComments(comment['body']);
    tempJson["text"].add(comment['body']);
    for (final comment in splitComment) {
      final newTime = lengthCalculation(comment, startTime);
      final newDialog = sink_comments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,$animation$comment\n");
      startTime = newTime;
    }
  }

  sink_tts.write(json.encode(tempJson));
  sink_comments.close();

  int prevMinutes = int.parse(startTime[2] + startTime[3]);
  int prevSeconds = int.parse(startTime[5] + startTime[6]);
  int prevMilliseconds = int.parse(startTime.substring(8)) * 10;

  return (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000));
  //return errors
}

Future<List<String>> generateCommand(int end, int fps, String fileType) async {
  List<String> command = ["-i", "./defaults/video1.mp4"];
  List<String> inputStreams = [];

  final tts = Directory('./.temp/tts').list();
  int i = 1;
  await for (final value in tts) {
    command.addAll(["-i", value.path]);
    inputStreams.add("[${i}:a]");
    i++;
  }

  command.addAll([
    '-map',
    '0:v',
    '-map',
    '[final_a]',
    '-ss',
    '0ms',
    '-to',
    '${end + 100}ms',
    '-filter_complex',
    '${inputStreams.join(' ')} concat=n=${inputStreams.length}:v=0:a=1[final_a], crop=585:1080, subtitles=.temp/comments.ass, fps=$fps',
    './.temp/final.$fileType'
  ]);

  return command;
}
