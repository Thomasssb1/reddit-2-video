import 'package:reddit_2_video/reddit_2_video.dart' as reddit_2_video;
import '../lib/cmd.dart';

void main(List<String> arguments) async {
  var results = parse(arguments);
  if (results != null) {
    final Iterable<dynamic> postData = await reddit_2_video.getArticleInfo(
        results['subreddit'],
        results['sort'],
        results['nsfw'],
        int.parse(results['c']));
    if (postData.isNotEmpty) {
      reddit_2_video.generateVideo(postData, results['output'],
          results['video-path'], results['music-path'], results['framerate']);
    } else {
      print("No posts found... Try again.");
    }
  }
}
