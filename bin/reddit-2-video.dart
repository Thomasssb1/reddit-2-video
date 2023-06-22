import 'package:reddit_2_video/reddit_2_video.dart' as reddit_2_video;
import '../lib/cmd.dart';

import 'dart:io';

// enable preview ffplay
// add styling to title and fade in etc using .ass
void main(List<String> arguments) async {
  var results = parse(arguments);
  if (results != null) {
    print(results['post-confirmation']);
    final List<dynamic> postData = await reddit_2_video.getPostData(
        results['subreddit'],
        results['sort'],
        results['nsfw'],
        int.parse(results['c']),
        results['comment-sort'],
        results['post-confirmation']);
    if (postData.isNotEmpty) {
      reddit_2_video.generateVideo(
          postData,
          results['output'],
          results['video-path'],
          results['music-path'],
          int.parse(results['framerate']));
    } else {
      print("No posts found... Try again.");
    }
  }
}
