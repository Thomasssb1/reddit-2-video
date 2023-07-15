import 'dart:io';
import 'package:http/http.dart';

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

bool checkStatusCode(Response response, String type) {
  if (response.statusCode == 200) {
    return true;
  } else if (response.statusCode == 404) {
    printError(
        "Endpoint could not be found. Perhaps the reddit endpoint being accessed is down or unavailable. Please try again later. If the problem persists, post this as an issue on github https://github.com/Thomasssb1/reddit-2-video/issues\nError: ${response.statusCode}\nReason: ${response.reasonPhrase}");
  } else if (response.statusCode == 400) {
    printError(
        "Incorrect data was sent to the server. If the problem persists, post this as an issue on github https://github.com/Thomasssb1/reddit-2-video/issues along with the data below.\nError:${response.statusCode}\nIncorrect data being sent: $type\n${response.body}\nReason: ${response.reasonPhrase}");
  } else if (response.statusCode == 303) {
    printError(
        "Error occurred whilst attempting to get post data. It is likely that the endpoint used is inactive and needs to be changed. Post this as an issue on github https://github.com/Thomasssb1/reddit-2-video/issues if the problem persists.\nError: ${response.statusCode}\nReason: ${response.reasonPhrase}");
  } else {
    printError(
        "An unknown error occured when attempting to access the link.\nError: ${response.statusCode}\nReason: ${response.reasonPhrase}\n${response.body}");
  }
  return false;
}

void clearTemp() {
  final File tempFile = File("./.temp");
  tempFile.
}
