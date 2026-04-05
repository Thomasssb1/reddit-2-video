import 'dart:async';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/ffmpeg/ffmpeg_command.dart';
import 'package:reddit_2_video/reddit/reddit_http_retry.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:http/http.dart' as http;
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/subprocess.dart';
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
      logger.info(
        "Resolving direct Reddit post link.",
        section: LogSection.reddit,
      );
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
      logger.info(
        "Resolved post ${post.id} from r/${post.subreddit}.",
        section: LogSection.reddit,
      );

      if (log.contains(video.posts.first)) {
        throw PostAlreadyGeneratedException(
            message:
                "The link provided in --subreddit has already had a video been generated previously.",
            help:
                "If you have already generated a video for this post you can remove this from the log by running reddit-2-video flush with the -p argument supplied.");
      }
      log.temporaryAdd(video);
      logger.info(
        "Selected direct-link post ${video.posts.first.id}.",
        section: LogSection.reddit,
      );
      return video;
    }

    // create a new link that also contains the sort
    Uri subredditLink = Uri.https(
        "reddit.com", "/r/${command.subreddit}/${command.sort.name}.json");
    logger.info(
      "Fetching posts from r/${command.subreddit} sorted by ${command.sort.name}.",
      section: LogSection.reddit,
    );

    http.Response response = await RedditHttpRetry.retryHttp(subredditLink);
    logger.info(
      "Reddit returned status ${response.statusCode}.",
      section: LogSection.reddit,
    );

    if (response.statusCode == 200) {
      // generate json data
      var json = jsonDecode(utf8.decode(response.bodyBytes));
      // get all of the necessary data
      // title, id, body, upvotes, created, spoiler, media, nsfw and comment count
      final rawPosts = pick(json, 'data', 'children').asListOrEmpty((p0) => p0);
      logger.info(
        "Received ${rawPosts.length} post candidates from Reddit.",
        section: LogSection.reddit,
      );

      for (final p0 in rawPosts) {
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
              "An error occurred whilst trying to fetch the post. Ignoring post.",
              section: LogSection.reddit);
          continue;
        }
      }

      logger.info(
        "Found ${postData.length} eligible post${postData.length == 1 ? '' : 's'} after filtering.",
        section: LogSection.reddit,
      );

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
        logger.info(
          "Selected post ${video.posts.first.id}.",
          section: LogSection.reddit,
        );
        return video;
      }

      // if the user wants to confirm the post and the subreddit arg is not a link
      if (command.postConfirmation) {
        // iterate through each post collected previously
        for (final post in postData) {
          // output relevant information
          logger.underline(post.title, section: LogSection.reddit);
          print(
              "${ansiGreen}Upvotes: ${post.upvotes}     ${ansiYellow}Comments: ${post.commentCount} $ansiReset\n");
          print(
              "Created: ${post.created}, ${post.spoiler ? 'This post ${ansiRed}is${ansiReset} marked as a spoiler' : ''}\n");
          if (post.hasMedia) {
            print("Media: ${post.hasMedia}\n");
          }
          if (command.nsfw) {
            print(
                "This post is${post.nsfw ? '' : ' ${ansiRed}not${ansiReset}'} marked as NSFW.");
          }
          logger.underline(
              "Post ${postData.indexOf(post) + 1}/${postData.length}.",
              section: LogSection.reddit);
          logger.info(
              "Do you want to see the body of the post? [${ansiGreen}y${ansiReset}/${ansiRed}N${ansiReset}] ",
              section: LogSection.reddit);
          // read the cli for what the user entered
          String showBody = stdin.readLineSync() ?? 'n';
          // if the user entered yes
          if (showBody.toLowerCase() == 'y') {
            print(post.body);
          }
          logger.info(
              "Do you want to generate a video for this post? [${ansiGreen}y${ansiReset}/${ansiRed}N${ansiReset}] ",
              section: LogSection.reddit);
          if (command.type == RedditVideoType.multi) {
            logger.info(
              "You can also enter 'skip' to skip all remaining posts. ",
              section: LogSection.reddit,
            );
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
            logger.info("Fetching next post...\n", section: LogSection.reddit);
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
      if (postData.length < command.commentCount) {
        Warning.warn(
            "Not enough posts selected as specified by the count option (${command.commentCount}). Generating video with only the posts that you have selected.",
            section: LogSection.reddit);
      } else {
        postData = postData.sublist(0, command.commentCount);
      }
      RedditVideo video = RedditVideo(posts: postData, videoType: command.type);
      log.temporaryAdd(video);
      logger.info(
        "Selected ${video.posts.length} post${video.posts.length == 1 ? '' : 's'} for generation.",
        section: LogSection.reddit,
      );
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
    final outputFile = AppPaths.resolve(input.last);

    final result = await Subprocess.exec("ffmpeg", input,
        verbose: command.verbose, section: LogSection.generation);

    int code = result.exitCode;

    if (code != 0) {
      throw FFmpegCommandException(
          message: "Something went wrong when generating the video. Exiting.",
          command: input);
    }

    logger.success("Video successfully generated: ${outputFile.path}",
        section: LogSection.generation);

    if (command.youtubeShort) {
      List<File> segments = await splitVideo(
          input.last, command.fileType.name, index,
          verbose: command.verbose);
      logger.success(
          "Video successfully split into ${segments.length} YouTube shorts:",
          section: LogSection.split);
      for (var segment in segments) {
        logger.info(segment.absolute.path, section: LogSection.split);
      }
    }
  }

  Future<void> _generateFolderStructure(Directory dir) async {
    dir.createSync(recursive: true);
  }

  String get id => posts.map((e) => e.id).join("-");
}
