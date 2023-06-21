import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';

Future<Iterable> getPostData(String subreddit, String sort, bool nsfw,
    int commentCount, String commentSort, bool postConfirm) async {
  // make the network request
  var client = http.Client();
  late List<dynamic> data;
  try {
    var response =
        await client.get(Uri.https("reddit.com", "/r/$subreddit/$sort.json"));
    var json = jsonDecode(utf8.decode(response.bodyBytes));

    data = pick(json, 'data', 'children')
        .asListOrEmpty((p0) {
          if ((!p0('data', 'stickied').asBoolOrFalse())) {
            // ignore any comments pinned to the subreddit (normally mod posts)
            if ((p0('data', 'num_comments').asIntOrNull() ?? 0) >=
                commentCount) {
              // check if the post has enough comments specified with -c
              if (nsfw) {
                // if the user has nsfw tag set to true (default)
                return {
                  'title': p0('data', 'title').required().asString(),
                  'id': p0('data', 'id').asStringOrNull(),
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
                    'id': p0('data', 'id').asStringOrNull(),
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
        })
        .where((element) => element != null && element['id'] != null)
        .toList();
    if (postConfirm) {
      // for loop
    } else {
      final id = data[0]['id'];
      response = await client.get(Uri.https(
          "reddit.com", "/r/$subreddit/comments/$id.json?sort=$commentSort"));
      json = jsonDecode(utf8.decode(response.bodyBytes));
      data = pick(json, 1, 'data', 'children').asListOrEmpty((p0) {
        return {'body': p0('data', 'body'), 'author': p0('data', 'author')};
      });
      data = data.sublist(
          0, data.length < 3 * commentCount ? data.length : 3 * commentCount);
    }
  } catch (e) {
    //error handling
  } finally {
    client.close();
  }
  return data;
}

List<String> splitComments(String comment) {
  // the max amount of characters on screen
  const int splitAmount = 18;
  String commentPiece = "";
  List<String> newComment = [];
  for (final word in comment.split(' ')) {
    if (commentPiece.length + word.length < splitAmount) {
      commentPiece += "$word ";
    } else {
      newComment.add(commentPiece.substring(0, commentPiece.length - 1));
      commentPiece = "$word ";
    }
  }
  newComment.add(commentPiece.substring(0, commentPiece.length - 1));
  return newComment;
}

generateVideo(Iterable<dynamic> postData, String output,
    String backgroundVideoPath, String musicPath, int framerate) {
  // ffmpeg -i defaults/video1.mp4 -vf "subtitles=comments.srt" -ss 00:01:00 -to 00:01:10  output.mp4
}
