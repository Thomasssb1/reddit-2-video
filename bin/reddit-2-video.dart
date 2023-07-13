import 'package:reddit_2_video/log.dart';
import 'package:reddit_2_video/reddit_2_video.dart' as reddit_2_video;
import 'package:reddit_2_video/utils.dart';
import '../lib/cmd.dart';

// enable preview ffplay
// add styling to title and fade in etc using .ass
void main(List<String> arguments) async {
  var results = parse(arguments);
  if (results == 'flush') {
    flushLog();
  } else if (results != null) {
    final List<dynamic> postData = await reddit_2_video.getPostData(
      results['subreddit'],
      results['sort'],
      results['nsfw'],
      int.parse(results['count']),
      results['comment-sort'],
      results['post-confirmation'],
      results['type'],
    );
    if (postData.isNotEmpty) {
      reddit_2_video.generateVideo(
        postData,
        results['output'],
        results['video-path'],
        results['music'],
        int.parse(results['framerate']),
        results['ntts'],
        results['file-type'],
        results['verbose'],
        results['override'],
        results['video-path'],
      );
    } else {
      printError("No post(s) found... Try again.");
    }
  }
}
