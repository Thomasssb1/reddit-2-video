import 'dart:io';
import 'package:http/http.dart';
import 'package:wav/wav.dart';

/// returns a single string as a list which contains max 50 characters each string in the list
List<String> splitComments(
  String comment,
) {
  // remove any links from the comment
  comment = comment
      //.replaceAll(RegExp(r'''[^\w\d' "]+'''), ' ')
      .replaceAll(RegExp(r'''(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w\.-]*)'''), ' ')
      .replaceAll(RegExp(' {2,}'), ' ')
      .trim();
  // the number of characters that is the maximum
  const int splitAmount = 50;
  String commentPiece = "";
  List<String> newComment = [];
  // loop through each word that is split from the comment (split by a space)
  for (final word in comment.split(
    ' ',
  )) {
    // if the total count is still less than the max amount then append it to the string
    if (commentPiece.length + word.length < splitAmount) {
      commentPiece += "$word ";
    } else {
      // if the total count is more than the max amount then add the string to a list
      newComment.add(commentPiece.substring(0, commentPiece.length - 1));
      // set the new start of the string to the word
      commentPiece = "$word ";
    }
  }
  // add the final string that was left over
  newComment.add(commentPiece.substring(0, commentPiece.length - 1));
  return newComment;
}

/// calculate the end time of the new message from the previous time and duration
String lengthCalculation(
  double duration,
  String startTime,
) {
  // 0:00:00.00 -> h:mm:ss.ms
  // infer the data from the string used in .ass file
  int prevMinutes = int.parse(startTime[2] + startTime[3]);
  int prevSeconds = int.parse(startTime[5] + startTime[6]);
  int prevMilliseconds = int.parse(startTime.substring(8)) * 10;
  // get the new end time
  Duration calculatedTime = Duration(
      milliseconds: (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000)) + (duration * 1000).round());
  // if the time goes over an hour (idk how? but maybe)
  if (calculatedTime.inHours > 0) {
    printError("Somehow the time has gone over an hour for the video.. Aborting.");
    exit(124);
  }
  // generate a new string in the form h:mm:ss.ms
  String newTime =
      "0:${calculatedTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${calculatedTime.inSeconds.remainder(60).toString().padLeft(2, '0')}.${calculatedTime.inMilliseconds.remainder(1000).toString().padRight(2, '0').substring(0, 2)}";
  return newTime;
}

/// print with red text
void printError(
  String message,
) {
  print("\x1b[31m$message\x1b[0m");
}

/// print with orange text
void printWarning(
  String message,
) {
  print("\x1b[33m$message\x1b[0m");
}

/// print with green text
void printSuccess(
  String message,
) {
  print("\x1b[32m$message\x1b[0m");
}

/// print with underlined text
void printUnderline(
  String message,
) {
  print("\x1b[4m$message\x1b[0m");
}

/// print the usage formatted with colours for particular uses
void printHelp(
  String usage,
) {
  var bracketsRegex = RegExp(r'\((defaults.+)\)');
  var sqBracketsRegex = RegExp(r'\[(.*?)\]');
  var dashRegex = RegExp(r'(?!-level|-colour|-domain)(\-\S+)');

  for (final match in bracketsRegex.allMatches(usage)) {
    usage = usage.replaceAll(match[0]!, '\x1b[33m${match[0]}\x1b[0m');
  }
  for (final match in sqBracketsRegex.allMatches(usage)) {
    if (match[0] != '[no-]') {
      usage = usage.replaceAll(match[0]!, '\x1b[35m${match[0]}\x1b[0m');
    }
  }
  for (final match in dashRegex.allMatches(usage)) {
    usage = usage.replaceAll(match[0]!, '\x1b[32m${match[0]}\x1b[0m');
  }
  print(usage);
}

/// check if the http request contained an error
///
/// returns [true] if not and [false] if so
bool checkStatusCode(
  Response response,
  String type,
) {
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

/// clear all of tts files inside of .temp/tts and clear any data in temporary files
void clearTemp() async {
  // get the tts folder and delete it
  final Directory tempTTSFolder = Directory("./.temp/tts");
  await tempTTSFolder.delete(recursive: true).then((_) => null).catchError((error) {
    printError(
        "Unable to clear the temporary data. This will not affect future video generation but will cause ~a few MB stored in the temporary folder. Error: $error");
    return;
  });
  // make a new tts folder that is empty
  await (Directory('./.temp/tts').create().then((_) => null).catchError((error) {
    printError(
        "Unable to create TTS folder. If this continues, then post this as an issue on github error https://github.com/Thomasssb1/reddit-2-video/issues along with steps to reproduce this issue. Error: $error");
    return;
  }));
  // clear the temporary .ass file
  final File assFile = File("./.temp/comments.ass");
  assFile.writeAsStringSync('');
}

/// calls the pythhon tts.py file whilst passing arguments
Future<double> generateTTS(
  String text,
  int counter,
  bool ntts,
  String voiceAccent,
  startTime,
) async {
  // $ python lib/tts.py text, int, 1/0, accent, voice
  var ttsResult =
      await Process.run('python', ["lib/tts.py", text, (counter - 1).toString(), ntts ? "1" : "0", voiceAccent]);
  // if the process did not complete successfully
  if (ttsResult.exitCode != 0) {
    printError("TTS failed.\nExit code: ${ttsResult.exitCode}\nError: ${ttsResult.stderr}");
    exit(0);
  }
  // get the length of the new wav file containing the tts
  final wav = await Wav.readFile("./.temp/tts/tts-${counter - 1}.wav");
  return wav.duration;
}
