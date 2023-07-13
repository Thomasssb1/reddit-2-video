import 'dart:io';

List<String> splitComments(String comment) {
  // the max amount of characters on screen
  comment = comment
      //.replaceAll(RegExp(r'''[^\w\d' "]+'''), ' ')
      .replaceAll(RegExp(r'''(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w\.-]*)'''), ' ')
      .replaceAll(RegExp(' {2,}'), ' ')
      .trim();
  const int splitAmount = 18;
  String commentPiece = "";
  List<String> newComment = [];
  for (final word in comment.split(
    ' ',
  )) {
    if (commentPiece.length + word.length < splitAmount) {
      commentPiece += "$word ";
    } else {
      newComment.add(commentPiece.substring(0, commentPiece.length - 1));
      commentPiece = "$word ";
    }
  }
  newComment.add(commentPiece.substring(0, commentPiece.length - 1));
  return newComment;
}

String lengthCalculation(String message, String startTime) {
  // start (hh:mm:ss,ms)--> end (hh:mm:ss,ms)
  int timePerChar = 75;

  int prevMinutes = int.parse(startTime[2] + startTime[3]);
  int prevSeconds = int.parse(startTime[5] + startTime[6]);
  int prevMilliseconds = int.parse(startTime.substring(8)) * 10;
  Duration calculatedTime = Duration(
      milliseconds: (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000)) + (message.length * timePerChar));
  if (calculatedTime.inHours > 0) {
    printError("Somehow the time has gone over an hour for the video.. Aborting.");
    exit(124);
  }
  String newTime =
      "0:${calculatedTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${calculatedTime.inSeconds.remainder(60).toString().padLeft(2, '0')}.${calculatedTime.inMilliseconds.remainder(1000).toString().padRight(2, '0').substring(0, 2)}";
  return newTime;
}

checkLog(String id) async {
  final File logFile = File("./.temp/visited_log.txt");
  final String content = await logFile.readAsString();
  final List<String> logs = content.split('\n');
  if (logs.contains(id)) {
    return true;
  } else {
    final sink = logFile.openWrite(mode: FileMode.append);
    sink.writeln(id);
    sink.close();
    return false;
  }
}

void printError(String message) {
  print("\x1b[31m$message\x1b[0m");
}

void printWarning(String message) {
  print("\x1b[33m$message\x1b[0m");
}

void printSuccess(String message) {
  print("\x1b[32m$message\x1b[0m");
}

void printUnderline(String message) {
  print("\x1b[4m$message\x1b[0m");
}

void printHelp(String usage) {
  List<String> newMessage = [];
  bool options = false;
  bool defaults = false;
  for (final char in usage.split(" ")) {
    if (char.trimLeft().startsWith('--')) {
      newMessage.add("\x1b[32m$char\x1b[0m");
    } else if (char.trimLeft().startsWith('(defaults')) {
      defaults = true;
      newMessage.add("\x1b[33m$char\x1b[0m");
    } else if (defaults) {
      if (char.trimRight().endsWith(')')) {
        newMessage.add("\x1b[33m$char\x1b[0m");
        defaults = false;
      } else {
        newMessage.add("\x1b[33m$char\x1b[0m");
      }
    } else if (char.trimLeft().startsWith('[')) {
      if (!(char.trimRight().endsWith(']'))) {
        options = true;
      }
      newMessage.add("\x1b[35m$char\x1b[0m");
    } else if (options) {
      if (char.trimRight().endsWith(']')) {
        newMessage.add("\x1b[35m$char\x1b[0m");
        options = false;
      } else {
        newMessage.add("\x1b[35m$char\x1b[0m");
      }
    } else {
      newMessage.add(char);
    }
  }
  print(newMessage.join(' '));
}
