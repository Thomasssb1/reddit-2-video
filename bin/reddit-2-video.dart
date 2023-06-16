import 'package:reddit_2_video/reddit_2_video.dart' as reddit_2_video;
import '../lib/cmd.dart';

// remove any pinned posts/comments from selection ['stickied']

void main(List<String> arguments) async {
  var results = parse(arguments);
  if (results != null) {
    await reddit_2_video.getArticleInfo(results['subreddit'], results['sort']);
  }
}
