import 'dart:convert';
import 'dart:io';
import 'dart:js_interop';
import 'package:reddit_2_video/utils.dart';
import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

/// check if the visited_log.txt file contains the post that is currently being fetched
bool checkLog(Object? id) {
  // if an id does not exist for the post assume that it has already been generated
  if (id == null) {
    return true;
  }
  // open log file
  final File logFile = File("./.temp/visited_log.txt");
  try {
    /// [change to a stream instead so that it doesn't have to be fully read]
    // read the file and split the text into a list that can be read
    final String content = logFile.readAsStringSync();
    final List<String> logs = content.split('\n');
    // if the log contains that post id
    if (logs.contains(id)) {
      return true;
    } // if the log does not contain that post id
    else {
      return false;
    }
  } catch (e) {
    // catch the error and output
    printError('Error occurred when reading log file.\n$e');
    exit(1);
  }
}

/// write the id of the post being generated to the log
void writeToLog(dynamic post) {
  // open log file for writing
  final File logFile = File("./.temp/visited_log.txt");
  final sink = logFile.openWrite(mode: FileMode.append);
  // write new id on a new line
  sink.writeln(post['id']);
  sink.close();
}

/// remove all ids from the file or a specific id if specified
void flushLog(String? link) async {
  final File logFile = File("./.temp/visited_log.txt");
  if (link == null) {
    logFile.writeAsStringSync('');
  } else {
    var response = await http.get(Uri.parse("$link.json"));
    bool valid = checkStatusCode(response, "Post");
    if (valid) {
      var json = jsonDecode(utf8.decode(response.bodyBytes));
      try {
        String id = pick(json[0], 'data', 'children', 0, 'data', 'id').asStringOrThrow();
        final lines = await logFile.readAsLines();
        lines.removeWhere((element) => element == id);
        await logFile.writeAsString(lines.join('\n'));
      } catch (e) {
        printError("Incorrect link, the following link is not a valid link.\nLink: $link, \nError: $e");
        exit(1);
      }
    }
  }
}
