import 'dart:convert';
import 'dart:io';

import 'ffmpeg.dart';

import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

Future<List<dynamic>> getPostData(
    String subreddit, String sort, bool nsfw, int commentCount, String commentSort, bool postConfirm) async {
  // make the network request
  var client = http.Client();
  List<dynamic> postData = [];
  try {
    var response = await client.get(Uri.https("reddit.com", "/r/$subreddit/$sort.json"));
    var json = jsonDecode(utf8.decode(response.bodyBytes));

    List<dynamic> data = pick(json, 'data', 'children')
        .asListOrEmpty((p0) {
          if ((!p0('data', 'stickied').asBoolOrFalse())) {
            // ignore any comments pinned to the subreddit (normally mod posts)
            if ((p0('data', 'num_comments').asIntOrNull() ?? 0) >= commentCount) {
              // check if the post has enough comments specified with -c
              if (nsfw) {
                // if the user has nsfw tag set to true (default)
                return {
                  'title': p0('data', 'title').required().asString(),
                  'id': p0('data', 'id').asStringOrNull(),
                  'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
                  'created': p0('data', 'created_utc')
                      .letOrNull((pick) => DateTime.fromMicrosecondsSinceEpoch((pick.asDoubleOrNull() ?? 0.0).round())),
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
    if (postConfirm) {
      // for loop
    } else {
      final id = data[0]['id'];
      postData.add({"post": data[0]});
      var commentResponse =
          await client.get(Uri.https("reddit.com", "/r/$subreddit/comments/$id.json", {"sort": commentSort}));
      print(commentResponse.statusCode);
      var commentJson = jsonDecode(utf8.decode(commentResponse.bodyBytes));
      List<dynamic> commentData = pick(commentJson, 1, 'data', 'children')
          .asListOrEmpty((p0) {
            return {
              'body': p0('data', 'body').asStringOrNull(),
              'author': p0('data', 'author').asStringOrNull() ?? "Anonymous"
            };
          })
          .where((element) => element['body'] != null && (element['body'] ??= "").length <= 512)
          .toList();
      commentData =
          commentData.sublist(0, commentData.length < 3 * commentCount ? commentData.length : 3 * commentCount);
      postData.add({"comments": commentData});
    }
  } catch (e) {
    //error handling
  } finally {
    client.close();
  }
  return postData;
}

generateVideo(List<dynamic> postData, String output, String backgroundVideoPath, String? musicPath, int framerate,
    bool offlineTTS, String fileType) async {
  //var result = await Process.run(
  //'python', [r"D:\Executables\reddit-2-video\lib\tts.py"]);

  int end_ms = await generateSubtitles(offlineTTS, postData);

  List<String> command = await generateCommand(output, end_ms, framerate, fileType);
  final process = await Process.start('ffmpeg', command);
  process.stderr.transform(utf8.decoder).listen((data) {
    print(data);
  });
  stdin.pipe(process.stdin);
  await process.exitCode;
}

// ffmpeg -i defaults/video1.mp4 -i .temp/tts.wav -map 0:v -map 1:a -shortest -filter:v "subtitles=.temp/comments.srt:fontsdir=defaults/font:force_style='Fontname=Verdana,Alignment=10',crop=585:1080" -filter:a "atempo=1001/1000,asetrate=44100*1000/1001" -ss 00:00:00 -to 00:03:20  output.mp4
