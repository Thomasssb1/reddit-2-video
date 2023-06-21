import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

import 'package:ffmpeg_cli/ffmpeg_cli.dart';

Future<List<dynamic>> getPostData(String subreddit, String sort, bool nsfw,
    int commentCount, String commentSort, bool postConfirm) async {
  // make the network request
  var client = http.Client();
  List<dynamic> postData = [];
  try {
    var response =
        await client.get(Uri.https("reddit.com", "/r/$subreddit/$sort.json"));
    var json = jsonDecode(utf8.decode(response.bodyBytes));

    List<dynamic> data = pick(json, 'data', 'children')
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
      postData.add({"post": data[0]});
      var commentResponse = await client.get(Uri.https("reddit.com",
          "/r/$subreddit/comments/$id.json", {"sort": commentSort}));
      print(commentResponse.statusCode);
      var commentJson = jsonDecode(utf8.decode(commentResponse.bodyBytes));
      List<dynamic> commentData = pick(commentJson, 1, 'data', 'children')
          .asListOrEmpty((p0) {
            return {
              'body': p0('data', 'body').asStringOrNull(),
              'author': p0('data', 'author').asStringOrNull() ?? "Anonymous"
            };
          })
          .where((element) => element['body'] != null)
          .toList();
      commentData = commentData.sublist(
          0,
          commentData.length < 3 * commentCount
              ? commentData.length
              : 3 * commentCount);
      postData.add({"comments": commentData});
    }
  } catch (e) {
    //error handling
  } finally {
    client.close();
  }
  return postData;
}

List<String> splitComments(String comment) {
  // the max amount of characters on screen
  comment = comment
      .replaceAll(RegExp(r'''[^\w\d' "]+'''), ' ')
      .replaceAll(RegExp(' {2,}'), ' ')
      .trim();
  const int splitAmount = 18;
  String commentPiece = "";
  List<String> newComment = [];
  for (final word in comment.split(
    ' ',
  )) {
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

String lengthCalculation(String message, String startTime) {
  // start (hh:mm:ss,ms)--> end (hh:mm:ss,ms)
  int timePerChar = 100;

  int prevMinutes = int.parse(startTime[3] + startTime[4]);
  int prevSeconds = int.parse(startTime[6] + startTime[7]);
  int prevMilliseconds = int.parse(startTime.substring(9));
  Duration calculatedTime = Duration(
      milliseconds:
          (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000)) +
              (message.length * timePerChar));
  if (calculatedTime.inHours > 0) {
    return "Somehow the time has gone over an hour for the video.. Aborting.";
  }
  String newTime =
      "00:${calculatedTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${calculatedTime.inSeconds.remainder(60).toString().padLeft(2, '0')},${calculatedTime.inMilliseconds.remainder(1000).toString().padRight(3, '0')}";
  return newTime;
}

generateVideo(List<dynamic> postData, String output, String backgroundVideoPath,
    String? musicPath, int framerate) {
  var file = File("./comments.srt");
  var sink = file.openWrite();

  final List<String> splitTitle = splitComments(postData[0]['post']['title']);
  String startTime = "00:00:00,000";
  for (int i = 0; i < splitTitle.length; i++) {
    final newTime = lengthCalculation(splitTitle[i], startTime);
    final newDialog =
        sink.write("${i + 1}\n$startTime --> $newTime\n${splitTitle[i]}\n");
    startTime = newTime;
  }
  int lineCount = splitTitle.length;
  for (final comment in postData[1]['comments']) {
    List<String> splitComment = splitComments(comment['body']);
    for (int j = 0; j < splitComment.length; j++) {
      final newTime = lengthCalculation(splitComment[j], startTime);
      lineCount += 1;
      final newDialog = sink
          .write("$lineCount\n$startTime --> $newTime\n${splitComment[j]}\n");
      startTime = newTime;
    }
  }

  sink.close();
}

// ffmpeg -i defaults/video1.mp4 -vf "subtitles=comments.srt:fontsdir=defaults/font:force_style='Fontname=Verdana,Alignment=10',crop=585:1080" -ss 00:01:00 -to 00:01:10  output.mp401:10  output.mp4
