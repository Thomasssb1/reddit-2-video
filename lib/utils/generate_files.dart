/*
reddit-2-video/
└── .temp/
    ├── subreddit_id-post_id/
    │   ├── config/
    │   ├── tts/
    │   ├── comments.ass
    │   └── video.mp4
    └── visited_log.txt

*/

import 'dart:io';
import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/utils/prettify.dart';

// need to make it suitable for multi type option
generateFiles(String id) async {
  Directory idDirectory = Directory("$prePath/.temp/$id/tts");
  if (idDirectory.existsSync()) {
    await Directory("$prePath/.temp/$id")
        .delete(recursive: true)
        .catchError((_) {
      // implement pop back to find new post
      printError(
          "Something went wrong when deleting a folder (.temp/$id). It is likely being used by another process, you can either teminate the process or delete it manually.\nThis error was caused by a folder already existing containing data about the post you are querying.");
      exit(1);
    });
  }
  await idDirectory.create(recursive: true);
  await File("$prePath/.temp/$id/comments.ass").create();
}
