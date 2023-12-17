import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/http.dart';
import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';
import 'package:reddit_2_video/utils/prepath.dart';

final int subredditIDCount = 8;

/// check if the visited_log.txt file contains the post that is currently being fetched
bool checkLog(
  Object? id,
) {
  // if an id does not exist for the post assume that it has already been generated
  if (id == null) {
    return true;
  }
  // open log file
  final File logFile = File("$prePath/.temp/visited_log.txt");
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
void writeToLog(
  String id,
  bool isMulti,
) {
  // open log file for writing
  final File logFile = File("$prePath/.temp/visited_log.txt");
  final sink = logFile.openWrite(mode: FileMode.append);
  // write new id on a new line
  if (isMulti) {
    // add 2 to account for inclusivity and -
    String subredditID = id.substring(0, subredditIDCount + 2);
    id.replaceAll(subredditID, '').split('-').forEach((id) {
      print("$subredditID$id");
      sink.writeln("$subredditID$id");
    });
  } else {
    sink.writeln(id);
  }
  sink.close();
}

/// remove all ids from the file or a specific id if specified
void flushLog(
  String? link,
) async {
  // open log file
  final File logFile = File("$prePath/.temp/visited_log.txt");
  // if the user wants to remove every entry
  if (link == null) {
    // write nothing to file to overwrite data
    logFile.writeAsStringSync('');
  } // if the user wants to remove a specific post
  else {
    // send response and check if valid
    var response = await http.get(Uri.parse("$link.json"));
    bool valid = checkStatusCode(response, "Post");
    if (valid) {
      var json = jsonDecode(utf8.decode(response.bodyBytes));
      // try/catch used if an incorrect link is given which doesn't contain an id in the json data
      try {
        String id = pick(json[0], 'data', 'children', 0, 'data', 'id')
            .asStringOrThrow();
        String subredditId =
            pick(json[0], 'data', 'children', 0, 'data', 'subreddit_id')
                .asStringOrThrow();
        // read lines as a list and remove any entries that match the id
        final lines = await logFile.readAsLines();
        lines.removeWhere((element) => element == "$subredditId-$id");
        // turn the list into a \n split file
        await logFile.writeAsString(lines.join('\n'));
      } catch (e) {
        printError(
            "Incorrect link, the following link is not a valid link.\nLink: $link, \nError: $e");
        exit(1);
      }
    }
  }
}
