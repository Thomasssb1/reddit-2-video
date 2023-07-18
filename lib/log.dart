import 'dart:io';

import 'package:reddit_2_video/utils.dart';

checkLog(Object? id) {
  if (id == null) {
    return true;
  }
  final File logFile = File("./.temp/visited_log.txt");
  try {
    final String content = logFile.readAsStringSync();
    final List<String> logs = content.split('\n');
    if (logs.contains(id)) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    printError('Error occured when reading log file.\n$e');
    exit(1);
  }
}

void writeToLog(dynamic post) {
  final File logFile = File("./.temp/visited_log.txt");
  final sink = logFile.openWrite(mode: FileMode.append);
  sink.writeln(post['id']);
  sink.close();
  // error handling
}

flushLog(String link) async {
  print(link);
  final File logFile = File("./.temp/visited_log.txt");
  logFile.writeAsStringSync('');
}
