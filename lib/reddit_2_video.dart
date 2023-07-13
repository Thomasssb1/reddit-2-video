import 'dart:convert';
import 'dart:io';

import 'package:reddit_2_video/utils.dart';
import 'package:reddit_2_video/log.dart';

import 'ffmpeg.dart';

import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

Future<List<dynamic>> getPostData(String subreddit, String sort, bool nsfw, int commentCount, String commentSort,
    bool postConfirm, String type) async {
  // make the network request
  var client = http.Client();
  List<dynamic> postData = [];
  bool isLink = RegExp(r'''(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w\.-]*)''').hasMatch(subreddit);
  Uri linkUri = Uri.https("reddit.com", "gd/r/$subreddit/$sort.json");
  if (isLink) {
    linkUri = Uri.parse("$subreddit.json");
    if (type == 'multi') {
      printError("Unable to use multi type with a direct link to a post, use a subreddit instead or change type.");
      exit(1);
    }
  }
  var response = await client.get(Uri.https(linkUri.authority, linkUri.path));
  bool valid = checkStatusCode(response, "Post");
  if (valid) {
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
                  'body': p0('data', 'selftext').asStringOrNull() ?? '',
                  'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
                  'created': p0('data', 'created').letOrNull(
                      (pick) => DateTime.fromMillisecondsSinceEpoch(((pick.asDoubleOrNull() ?? 0.0) * 1000).round())),
                  'spoiler': p0('data', 'spoiler').asBoolOrFalse(),
                  'media': p0('data', 'media').asBoolOrFalse(),
                  'nsfw': p0('data', 'over_18').asBoolOrNull() ?? false,
                  'comments': p0('data', 'num_comments').asIntOrNull() ?? 0
                };
              } else {
                // if the user has nsfw tag set to false
                if (!(p0('data', 'over_18').asBoolOrNull() ?? true)) {
                  // if the post has nsfw tag set to false
                  return {
                    'title': p0('data', 'title').required().asString(),
                    'id': p0('data', 'id').asStringOrNull(),
                    'body': p0('data', 'selftext').asStringOrNull() ?? '',
                    'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
                    'created': p0('data', 'created').letOrNull(
                        (pick) => DateTime.fromMicrosecondsSinceEpoch((pick.asDoubleOrNull() ?? 0.0).round())),
                    'spoiler': p0('data', 'spoiler').asBoolOrFalse(),
                    'media': p0('data', 'media').asBoolOrFalse(),
                    'nsfw': false,
                    'comments': p0('data', 'num_comments').asIntOrNull() ?? 0
                  };
                }
              }
            }
          }
          // filter out any null values from the values returned
        })
        .where((element) => element != null && element['id'] != null && checkLog(element['id']) == false)
        .toList();
    if (type != 'multi' && !postConfirm) {
      postData = [data[0]];
    }
    if (postConfirm && !isLink) {
      for (final post in data) {
        printUnderline("${post['title']}\n");
        print("\x1b[32mUpvotes: ${post['upvotes']}     \x1b[33mComments: ${post['comments']} \x1b[0m\n");
        print(
            "Created: ${post['created']}, ${post['spoiler'] ? 'This post \x1b[31mis\x1b[0m marked as a spoiler' : ''}\n");
        if (post['media']) {
          print("Media: ${post['media']}\n");
        }
        if (nsfw) {
          print("This post is${post['nsfw'] ? '' : ' \x1b[31mnot\x1b[0m'} marked as NSFW.");
        }
        printUnderline("Post ${data.indexOf(post) + 1}/${data.length}.");
        print("Do you want to generate a video for this post? [\x1b[32my\x1b[0m/\x1b[31mN\x1b[0m] ");
        if (type == 'multi') {
          print("You can also enter 'skip' to skip all remaining posts. ");
        }
        String continueGeneration = stdin.readLineSync() ?? 'n';
        if (continueGeneration.toLowerCase() == 'y') {
          postData.add(post);
          if (type != 'multi') {
            break;
          }
        } else if (continueGeneration.toLowerCase() == 'skip' && type == 'multi') {
          break;
        } else {
          print("Continuing to find a new post...\n");
          if (post == data.last && type != 'multi') {
            printError(
                "All posts have been searched for the subreddit $subreddit, try again later or use a different sort term..");
            exit(1);
          }
        }
      }
    }
    if (type == 'comments') {
      postData = postData.map((e) => [e['title'], e['body']]).toList();
      var commentResponse = await client.get(Uri.https(
          "reddit.com", isLink ? linkUri.path : "/r/$subreddit/comments/${data[0]['id']}.json", {"sort": commentSort}));
      bool valid = checkStatusCode(response, "Comment");
      if (valid) {
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
        writeToLog(postData[0]);
        postData[0].addAll(commentData.map((e) => e['body']).toList());
      } else {
        exit(1);
      }
    } else if (type == 'post') {
      writeToLog(postData[0]);
      postData = postData.map((e) => [e['title'], e['body']]).toList();
    } else if (type == 'multi') {
      if (!postConfirm) {
        if (data.length < commentCount) {
          printWarning(
              "Currently unable to retrieve the specified number of posts ($commentCount). Generating video anyways with ${data.length} posts instead.");
        } else {
          postData = data.sublist(0, commentCount);
        }
      } else {
        if (postData.isEmpty) {
          printError("You haven't selected any posts. Retry but ensure that atleast one post is selected.");
          exit(1);
        }
        if (postData.length < commentCount) {
          printWarning(
              "You haven't selected enough posts as specified by the count option ($commentCount). Generating video with only the posts that you have selected.");
        } else {
          if (postData.length > commentCount) {
            printWarning(
                "You have selected too many posts as specified by the count option ($commentCount). Generating video with only $commentCount posts instead. You can change this by editing the -count option.");
          }
          postData = postData.sublist(0, commentCount);
        }
      }
      postData.forEach(writeToLog);
      postData = postData.map((e) => [e['title'], e['body']]).toList();
    }
    client.close();
    return postData;
  } else {
    exit(1);
  }
}

generateVideo(List<dynamic> postData, String output, String backgroundVideoPath, List<String> music, int framerate,
    bool offlineTTS, String fileType, bool verbose, bool override, String video) async {
  print("Starting TTS generation...");
  var result = await Process.run('python', [r"lib/tts.py"]);
  if (result.exitCode != 0) {
    printError("TTS failed.\nExit code: ${result.exitCode}\nError: ${result.stderr}");
  } else {
    printSuccess("TTS successfully generated.");
  }

  int end_ms = await generateSubtitles(offlineTTS, postData);

  List<String> command = await generateCommand(output, end_ms, framerate, fileType, music, video, override);
  final process = await Process.start('ffmpeg', command);
  late String errorMessage;
  process.stderr.transform(utf8.decoder).listen((data) {
    if (verbose || data.contains('Overwrite? [y/N]')) {
      stdout.write(data);
      errorMessage = data;
    }
  });
  stdin.pipe(process.stdin);
  int code = await process.exitCode;
  if (code == 0) {
    printSuccess(
        "Video generation completed, check the directory you provided for the final video otherwise it is in the directory that you called the command from.");
  } else {
    printError(
        "Video generation unable to be completed. The most common errors include using incorrect path to files, make sure to check before trying again.\nError code: $code\n$errorMessage");
  }
}
