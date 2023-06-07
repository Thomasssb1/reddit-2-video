import 'package:reddit_2_video/reddit_2_video.dart' as reddit_2_video;
import '../lib/cmd.dart';

void main(List<String> arguments) async {
  var results = parse(arguments);
  if (results != null) {
    var data = await reddit_2_video.getArticleInfo(
        results['subreddit'], results['sort']);
    print(data);
  }
}
