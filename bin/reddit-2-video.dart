import 'package:reddit_2_video/log.dart';
import 'package:reddit_2_video/reddit_2_video.dart' as reddit_2_video;
import 'package:reddit_2_video/utils.dart';
import '../lib/cmd.dart';
import 'dart:io';
import 'package:args/args.dart';

// enable preview ffplay
// add styling to title and fade in etc using .ass
void main(List<String> arguments) async {
  if (await File('./.temp/tts/.gitkeep').exists()) {
    await File('./.temp/tts/.gitkeep').delete().catchError((error) {
      printError(
          "Something went wrong when trying to delete a temporary file. To fix this you can go to the ./reddit-2-video/.temp/tts folder and delete the .gitkeep file. Error: $error");
      exit(1);
    });
  }
  var results = parse(arguments);
  if (results['command'] == null) {
    final List<dynamic> postData = await reddit_2_video.getPostData(
      results['args']['subreddit'],
      results['args']['sort'],
      results['args']['nsfw'],
      int.parse(results['args']['count']),
      results['args']['comment-sort'],
      results['args']['post-confirmation'],
      results['args']['type'],
    );
    if (postData.isNotEmpty) {
      reddit_2_video.generateVideo(
        postData,
        results['args']['output'],
        results['args']['video-path'],
        results['args']['music'],
        int.parse(results['args']['framerate']),
        results['args']['ntts'],
        results['args']['file-type'],
        results['args']['verbose'],
        results['args']['override'],
        results['args']['video-path'],
      );
    } else {
      printError("No post(s) found... Try again.");
    }
  } else if (results['command'] == 'flush') {
    flushLog(results['args']['post']);
  }
}
