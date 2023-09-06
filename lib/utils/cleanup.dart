import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/prepath.dart';
import 'dart:io';

deleteFolderContents(String path, [bool recreate = true]) async {
  // get the tts folder and delete it
  final Directory tempTTSFolder = Directory(path);
  await tempTTSFolder
      .delete(recursive: true)
      .then((_) => null)
      .catchError((error) {
    printError(
        "Unable to clear the temporary data. This will not affect future video generation but will cause ~a few MB stored in the temporary folder.\nError: $error");
    return;
  });
  if (recreate) {
    // make a new tts folder that is empty
    await (Directory(path).create().then((_) => null).catchError((error) {
      printError(
          "Unable to create $path folder. If this continues, then post this as an issue on github error https://github.com/Thomasssb1/reddit-2-video/issues along with steps to reproduce this issue. Error: $error");
      return;
    }));
  }
}

/// clear all of tts files inside of .temp/tts and clear any data in temporary files
clearTemp() async {
  await deleteFolderContents("$prePath/.temp/tts");
  await deleteFolderContents("$prePath/.temp/config", false);

  // clear the temporary .ass file
  final File assFile = File("$prePath/.temp/comments.ass");
  assFile.writeAsStringSync('');
  final File videoFile = File("$prePath/.temp/video.mp4");
  await videoFile.delete().then((_) => null).catchError((error) {
    printError(
        "Unable to delete the temporary video. This will not affect future video generation but will cause ~a few MB stored in the temporary folder.\nError: $error");
  });
}
