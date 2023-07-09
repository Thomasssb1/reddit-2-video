import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:reddit_2_video/utils.dart';

import 'ffmpeg.dart';

import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

Future<List<dynamic>> getPostData(
    String subreddit, String sort, bool nsfw, int commentCount, String commentSort, bool postConfirm) async {
  // make the network request
  var client = http.Client();
  List<dynamic> postData = [];
  try {
    bool isLink = RegExp(r'''(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w\.-]*)''').hasMatch(subreddit);
    Uri linkUri = Uri.https("reddit.com", "/r/$subreddit/$sort.json");
    if (isLink) {
      linkUri = Uri.parse("$subreddit.json");
    }
    var response = await client.get(Uri.https(linkUri.authority, linkUri.path));
    var json = jsonDecode(utf8.decode(response.bodyBytes));
    List<dynamic> data = pick(isLink ? json[0] : json, 'data', 'children')
        .asListOrEmpty((p0) {
          if ((!p0('data', 'stickied').asBoolOrFalse())) {
            // ignore any comments pinned to the subreddit (normally mod posts)
            if ((p0('data', 'num_comments').asIntOrNull() ?? 0) >= commentCount) {
              // check if the post has enough comments specified with -c
              if (isLink ? true : nsfw) {
                // if the user has nsfw tag set to true (default)
                return {
                  'title': p0('data', 'title').required().asString(),
                  'id': p0('data', 'id').asStringOrNull(),
                  'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
                  'created': p0('data', 'created_utc').letOrNull(
                      (pick) => DateTime.fromMillisecondsSinceEpoch(((pick.asDoubleOrNull() ?? 0.0) * 1000).round())),
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
                    'created': p0('data', 'created_utc').letOrNull(
                        (pick) => DateTime.fromMicrosecondsSinceEpoch((pick.asDoubleOrNull() ?? 0.0).round())),
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
    if (postConfirm && !isLink) {
      // for loop
    } else {
      final id = data[0]['id'];
      postData.add({"post": data[0]});
      var commentResponse = await client.get(
          Uri.https("reddit.com", isLink ? linkUri.path : "/r/$subreddit/comments/$id.json", {"sort": commentSort}));
      print(commentResponse.statusCode);
      var commentJson = jsonDecode(utf8.decode(commentResponse.bodyBytes));
      List<dynamic> commentData = pick(commentJson, 1, 'data', 'children')
          .asListOrEmpty((p0) {
            return {
              'body': p0('data', 'body').asStringOrNull(),
              'author': p0('data', 'author').asStringOrNull() ?? "Anonymous"
            };
          })
          .where((element) =>
              element['body'] != null && (element['body'] ??= "").length <= 512 && element['body'] != "[removed]")
          .toList();
      commentData =
          commentData.sublist(0, commentData.length < 3 * commentCount ? commentData.length : 3 * commentCount);
      postData.add({"comments": commentData});
    }
  } catch (e) {
    print(e);
    //error handling
  } finally {
    client.close();
  }
  return postData;
}

generateVideo(List<dynamic> postData, String output, String backgroundVideoPath, List<String> music, int framerate,
    bool offlineTTS, String fileType, bool verbose) async {
  //var result = await Process.run(
  //'python', [r"D:\Executables\reddit-2-video\lib\tts.py"]);

  int end_ms = await generateSubtitles(offlineTTS, postData);

  List<String> command = await generateCommand(output, end_ms, framerate, fileType, music);
  final process = await Process.start('ffmpeg', command);
  late String errorMessage;
  var messages = process.stderr.transform(utf8.decoder).listen((data) {
    if (verbose || data.contains('Overwrite? [y/N]')) {
      print(data);
      errorMessage = data;
    }
  });
  stdin.pipe(process.stdin);
  int code = await process.exitCode;
  if (code == 0) {
    print(
        "Video generation completed, check the directory you provided for the final video otherwise it is in the directory that you called the command from.");
  } else {
    print(
        "Video generation unable to be completed. The most common errors include using incorrect path to files, make sure to check before trying again.\nError code: $code\n$errorMessage");
  }
}
