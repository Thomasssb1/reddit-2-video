import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';

Future<Iterable> getArticleInfo(
    String subreddit, String sort, bool nsfw, int commentCount) async {
  // make the network request
  var client = http.Client();
  late final dynamic json;
  try {
    var response =
        await client.get(Uri.https("reddit.com", "/r/$subreddit/$sort.json"));
    json = jsonDecode(utf8.decode(response.bodyBytes));
  } catch (e) {
    // do error handling
  } finally {
    client.close();
  }
  Iterable<dynamic> data = pick(json, 'data', 'children').asListOrEmpty((p0) {
    if ((!p0('data', 'stickied').asBoolOrFalse())) {
      // ignore any comments pinned to the subreddit (normally mod posts)
      if ((p0('data', 'num_comments').asIntOrNull() ?? 0) >= commentCount) {
        // check if the post has enough comments specified with -c
        if (nsfw) {
          // if the user has nsfw tag set to true (default)
          return {
            'title': p0('data', 'title').required().asString(),
            'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
            'created': p0('data', 'created_utc').letOrNull((pick) =>
                DateTime.fromMicrosecondsSinceEpoch(
                    (pick.asDoubleOrNull() ?? 0.0).round())),
            'spoiler': p0('data', 'spoiler').asBoolOrFalse(),
            'media': p0('data', 'media').asBoolOrFalse()
          };
        } else {
          // if the user has nsfw tag set to false
          if (!(p0('data', 'over_18').asBoolOrNull() ?? true)) {
            // if the post has nsfw tag set to false
            return {
              'title': p0('data', 'title').required().asString(),
              'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
              'created': p0('data', 'created_utc').letOrNull((pick) =>
                  DateTime.fromMicrosecondsSinceEpoch(
                      (pick.asDoubleOrNull() ?? 0.0).round())),
              'spoiler': p0('data', 'spoiler').asBoolOrFalse(),
              'media': p0('data', 'media').asBoolOrFalse()
            };
          }
        }
      }
    }
    // filter out any null values from the values returned
  }).where((element) => element != null);
  print(data);
  print(data.length);
  return data;
}

generateVideo(Iterable<dynamic> postData, String output,
    String backgroundVideoPath, String musicPath, int framerate) {
  // ffmpeg -i defaults/video1.mp4 -vf "subtitles=comments.srt" -ss 00:01:00 -to 00:01:10  output.mp4
}
