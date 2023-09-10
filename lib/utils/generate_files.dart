/*
reddit-2-video/
└── .temp/
    ├── post_id/
    │   ├── config/
    │   ├── tts/
    │   ├── comments.ass
    │   └── video.mp4
    └── visited_log.txt

*/

import 'dart:io';
import 'package:reddit_2_video/utils/prepath.dart';

// need to make it suitable for multi type option
generateFiles(String id) async {
  Directory idDirectory = Directory("$prePath/.temp/$id/tts");
  if (idDirectory.existsSync()) {
    await Directory("$prePath/.temp/$id").delete(recursive: true);
  }
  await idDirectory.create(recursive: true);
  await File("$prePath/.temp/$id/comments.ass").create();
}
