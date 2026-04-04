import 'dart:async';
import 'package:path/path.dart' as p;

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/ffmpeg/ffmpeg_command.dart';
import 'package:reddit_2_video/reddit/reddit_http_retry.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:http/http.dart' as http;
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/ffmpeg/splitter.dart';
import 'reddit/reddit_video_type.dart';
import 'exceptions/exceptions.dart';
import 'command/parsed_command.dart';
import 'dart:convert';
import 'package:deep_pick/deep_pick.dart';
import 'dart:io';

/// Stores the reddit post(s) for the specific vid to be generated as well as the videotype
///
class RedditVideo {
  final List<RedditPost> posts;
  final RedditVideoType videoType;
  Subtitles? subtitles;
  List<String> inputStreams = [];

  RedditVideo({
    required this.posts,
    required this.videoType,
  }) {
    _generateFolderStructure(AppPaths.resolveDir('.temp/$id'));
  }

  RedditVideo.single({
    required RedditPost post,
    required RedditVideoType videoType,
  }) : this(posts: [post], videoType: videoType);

  static Future<RedditVideo> parse(ParsedCommand command, Log log) async {
    // make client so that multiple https requests can be made easily
    List<RedditPost> postData = [];

    if (command.subredditIsLink) {
      if (command.type == RedditVideoType.multi) {
        // can't use a singular link if you want to have multiple posts
        throw ArgumentConflictException(
            "Unable to use multi type with a direct link to a post, use a subreddit instead or change type.",
            command.subreddit,
            command.type.name);
      }

      RedditPost post = await RedditPost.fromUrl(url: command.subreddit);
      RedditVideo video =
          RedditVideo.single(post: post, videoType: command.type);

      if (log.contains(video.posts.first)) {
        throw PostAlreadyGeneratedException(
            message:
                "The link provided in --subreddit has already had a video been generated previously.",
            help:
                "If you have already generated a video for this post you can remove this from the log by running reddit-2-video flush with the -p argument supplied.");
      }
      log.temporaryAdd(video);
      return video;
    }

    // create a new link that also contains the sort
    Uri subredditLink = Uri.https(
        "reddit.com", "/r/${command.subreddit}/${command.sort.name}.json");

    http.Response response = await RedditHttpRetry.retryHttp(subredditLink);

    if (response.statusCode == 200) {
      // generate json data
      var json = jsonDecode(utf8.decode(response.bodyBytes));
      // get all of the necessary data
      // title, id, body, upvotes, created, spoiler, media, nsfw and comment count

      for (final p0
          in pick(json, 'data', 'children').asListOrEmpty((p0) => p0)) {
        try {
          String id = p0('data', 'id').required().asString();
          String subreddit = p0('data', 'subreddit').required().asString();
          RedditPost post =
              RedditPost.fromId(subreddit: subreddit, id: id, json: p0('data'));

          if (!(!command.nsfw && post.nsfw) &&
              !post.stickied &&
              post.commentCount >= command.commentCount &&
              !log.contains(post)) {
            postData.add(post);
          }
        } on PickException {
          Warning.warn(
              "An error occurred whilst trying to fetch the post. Ignoring post.");
          continue;
        }
      }

      if (postData.isEmpty) {
        throw PostsExhaustedException(
            message:
                "No posts could be found for the subreddit. Try again with another subreddit.");
      }

      // if the type is not multi and the user does not need to select a post
      if (command.type != RedditVideoType.multi && !command.postConfirmation) {
        // get the first post
        RedditVideo video =
            RedditVideo.single(post: postData.first, videoType: command.type);
        log.temporaryAdd(video);
        return video;
      }

      // if the user wants to confirm the post and the subreddit arg is not a link
      if (command.postConfirmation) {
        // iterate through each post collected previously
        for (final post in postData) {
          // output relevant information
          printUnderline(post.title);
          print(
              "${Prettify.green}Upvotes: ${post.upvotes}     ${Prettify.yellow}Comments: ${post.commentCount} ${Prettify.reset}\n");
          print(
              "Created: ${post.created}, ${post.spoiler ? 'This post ${Prettify.red}is${Prettify.reset} marked as a spoiler' : ''}\n");
          if (post.hasMedia) {
            print("Media: ${post.hasMedia}\n");
          }
          if (command.nsfw) {
            print(
                "This post is${post.nsfw ? '' : ' ${Prettify.red}not${Prettify.reset}'} marked as NSFW.");
          }
          printUnderline(
              "Post ${postData.indexOf(post) + 1}/${postData.length}.");
          print(
              "Do you want to see the body of the post? [${Prettify.green}y${Prettify.reset}/${Prettify.red}N${Prettify.reset}] ");
          // read the cli for what the user entered
          String showBody = stdin.readLineSync() ?? 'n';
          // if the user entered yes
          if (showBody.toLowerCase() == 'y') {
            print(post.body);
          }
          print(
              "Do you want to generate a video for this post? [${Prettify.green}y${Prettify.reset}/${Prettify.red}N${Prettify.reset}] ");
          if (command.type == RedditVideoType.multi) {
            print("You can also enter 'skip' to skip all remaining posts. ");
          }
          // read the cli for what the user entered
          String continueGeneration = stdin.readLineSync() ?? 'n';
          // if the user entered yes
          if (continueGeneration.toLowerCase() == 'y') {
            // add post to postData
            postData.add(post);
            // if the type is not multiple then break the loop as only one post can be selected
            if (command.type != RedditVideoType.multi ||
                postData.length == command.commentCount) {
              break;
            }
          } // if the user entered skip and the type selected is multi
          else if (continueGeneration.toLowerCase() == 'skip' &&
              command.type == RedditVideoType.multi) {
            if (postData.isEmpty) {
              throw EmptyPostSelectionException(
                  message: "No posts have been selected, try again.");
            }
            break;
          } // if the user entered no or otherwise
          else {
            print("Fetching next post...\n");
            // if the post is the last post / if the user hasn't selected any posts but have multi type
            if (post == postData.last &&
                command.type != RedditVideoType.multi) {
              throw PostsExhaustedException(
                  message:
                      "All posts have been searched for the subreddit ${command.subreddit}, try again later or use a different sort term..");
            }
          }
        }
        if (postData.isEmpty) {
          throw EmptyPostSelectionException(
              message: "No posts have been selected, try again.");
        }
      }
      // commentCount is also responsible for the number of posts selected
      print("post length: ${postData.length}");
      if (postData.length < command.commentCount) {
        Warning.warn(
            "Not enough posts selected as specified by the count option (${command.commentCount}). Generating video with only the posts that you have selected.");
      } else {
        postData = postData.sublist(0, command.commentCount);
      }
      RedditVideo video = RedditVideo(posts: postData, videoType: command.type);
      log.temporaryAdd(video);
      return video;
    } else {
      throw RedditApiException(
          message:
              "An error occurred whilst trying to fetch the subreddit data. Try again later.",
          statusCode: response.statusCode);
    }
  }

  Future<void> generate(ParsedCommand command, BackgroundVideo backgroundVideo,
      File cutVideo, int index) async {
    if (subtitles == null) {
      throw ArgumentMissingException(
          "Subtitles not added to RedditVideo object. Subtitles are required in order to continue generation of the video.");
    }

    EmptyNoise? emptyNoise;
    if (command.type != RedditVideoType.post) {
      emptyNoise = EmptyNoise();
    }

    final resolvedEndCard = await command.endCard;

    FFmpegCommand ffmpegCommand = FFmpegCommand(
      subtitles: subtitles!,
      backgroundVideo: backgroundVideo,
      emptyNoise: emptyNoise,
      music: command.music,
      endCard: resolvedEndCard,
    );

    List<String> input = ffmpegCommand.generate(command, cutVideo, index);
    print(input);

    final process = await Process.start("ffmpeg", input,
        mode: ProcessStartMode.inheritStdio);

    int code = await process.exitCode;

    if (code != 0) {
      throw FFmpegCommandException(
          message: "Something went wrong when generating the video. Exiting.",
          command: input);
    }

    printSuccess(
        "Video successfully generated: [${p.basename(input.last)}](file://${File(input.last).absolute.path})!");

    if (command.youtubeShort) {
      List<File> segments =
          await splitVideo(input.last, command.fileType.name, index);
      printSuccess(
          "Video successfully split into ${segments.length} YouTube shorts:");
      for (var segment in segments) {
        print(
            "  - [${p.basename(segment.path)}](file://${segment.absolute.path})");
      }
    }
  }

  Future<void> _generateFolderStructure(Directory dir) async {
    dir.createSync(recursive: true);
  }

  String get id => posts.map((e) => e.id).join("-");
}
