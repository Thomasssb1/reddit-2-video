import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/prepath.dart';
import 'dart:io';

deleteFolders(String path) async {
  // get the tts folder and delete it
  final Directory tempTTSFolder = Directory(path);
  await tempTTSFolder.delete(recursive: true).then((_) => null).catchError((error) {
    printError(
        "Unable to clear the temporary data. This will not affect future video generation but will cause ~a few MB stored in the temporary folder. You can delete it yourself by deleting the folder: $path\nError: $error");
  });
}

/// clear all of tts files inside of .temp/ and clear any data in temporary files
clearTemp([String? id]) async {
  if (id != null) {
    await deleteFolders("$prePath\\.temp\\$id");
  } else {
    File visitedLog = File("$prePath\\.temp\\visited_log.txt");
    String contents = visitedLog.readAsStringSync();
    await deleteFolders("$prePath\\.temp");
    visitedLog.createSync(recursive: true);
    visitedLog.writeAsString(contents);
  }
}
