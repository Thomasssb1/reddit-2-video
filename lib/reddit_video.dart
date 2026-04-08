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
import 'package:reddit_2_video/utils/progress.dart';
import 'package:reddit_2_video/utils/subprocess/progress_parser.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
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

  static Future<List<RedditVideo>> parseRepeated({
    required ParsedCommand command,
    required Log log,
    void Function(int videoIndex)? onSelectionAttempt,
    void Function(int videoIndex, RedditVideo video)? onSelectionSuccess,
  }) async {
    final videos = <RedditVideo>[];

    for (var i = 0; i < command.repeat; i++) {
      onSelectionAttempt?.call(i);

      try {
        final video = await parse(command, log);
        videos.add(video);
        onSelectionSuccess?.call(i, video);
      } on PostsExhaustedException {
        if (videos.isEmpty) rethrow;
        logger.warning(
          'Only ${videos.length} of ${command.repeat} requested videos could be selected from ${command.subreddit}. Continuing with the available posts.',
          section: LogSection.reddit,
        );
        break;
      }
    }

    return videos;
  }

  static Future<List<RedditPost>> confirmPostSelection({
    required List<RedditPost> candidates,
    required ParsedCommand command,
    required Log log,
    String Function()? readLine,
  }) async {
    final selectedPosts = <RedditPost>[];
    final resolvedReadLine = readLine ?? () => stdin.readLineSync() ?? 'n';

    for (var index = 0; index < candidates.length; index++) {
      final post = candidates[index];

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
      logger.underline("Post ${index + 1}/${candidates.length}.",
          section: LogSection.reddit);
      logger.info(
          "Do you want to see the body of the post? [${ansiGreen}y${ansiReset}/${ansiRed}N${ansiReset}] ",
          section: LogSection.reddit);

      final showBody = resolvedReadLine();
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

      final continueGeneration = resolvedReadLine();
      if (continueGeneration.toLowerCase() == 'y') {
        selectedPosts.add(post);
        if (command.type != RedditVideoType.multi ||
            selectedPosts.length == command.commentCount) {
          break;
        }
      } else if (continueGeneration.toLowerCase() == 'skip' &&
          command.type == RedditVideoType.multi) {
        log.addPost(post);
        if (selectedPosts.isEmpty) {
          throw EmptyPostSelectionException(
              message: "No posts have been selected, try again.");
        }
        break;
      } else {
        log.addPost(post);
        logger.info("Fetching next post...\n", section: LogSection.reddit);
        if (index == candidates.length - 1 &&
            command.type != RedditVideoType.multi) {
          throw PostsExhaustedException(
              message:
                  "All posts have been searched for the subreddit ${command.subreddit}, try again later or use a different sort term..");
        }
      }
    }

    return selectedPosts;
  }

  static Future<RedditVideo> parse(ParsedCommand command, Log log) async {
    // make client so that multiple https requests can be made easily
    final postData = <RedditPost>[];

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
          logger.warning(
              "An error occurred whilst trying to fetch the post. Ignoring post.",
              section: LogSection.reddit);
          continue;
        }
      }

      final eligiblePosts = List<RedditPost>.unmodifiable(postData);
      logger.info(
        "Found ${eligiblePosts.length} eligible post${eligiblePosts.length == 1 ? '' : 's'} after filtering.",
        section: LogSection.reddit,
      );

      if (eligiblePosts.isEmpty) {
        throw PostsExhaustedException(
            message:
                "No posts could be found for the subreddit. Try again with another subreddit.");
      }

      // if the type is not multi and the user does not need to select a post
      if (command.type != RedditVideoType.multi && !command.postConfirmation) {
        // get the first post
        RedditVideo video = RedditVideo.single(
            post: eligiblePosts.first, videoType: command.type);
        log.temporaryAdd(video);
        logger.info("Selected post ${video.posts.first.id}.",
            section: LogSection.reddit);
        return video;
      }

      List<RedditPost> selectedPosts = List<RedditPost>.from(eligiblePosts);

      // if the user wants to confirm the post and the subreddit arg is not a link
      if (command.postConfirmation) {
        selectedPosts = await generationProgress.runWithOverlaySuspended(
          () => confirmPostSelection(
            candidates: eligiblePosts,
            command: command,
            log: log,
          ),
        );
        if (selectedPosts.isEmpty) {
          throw EmptyPostSelectionException(
              message: "No posts have been selected, try again.");
        }
      }
      if (selectedPosts.length < command.commentCount) {
        logger.warning(
            "Not enough posts selected as specified by the count option (${command.commentCount}). Generating video with only the posts that you have selected.",
            section: LogSection.reddit);
      } else {
        selectedPosts = selectedPosts.sublist(0, command.commentCount);
      }
      RedditVideo video =
          RedditVideo(posts: selectedPosts, videoType: command.type);
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
    final progressTask = generationProgress.createTask(
      title: 'Rendering final video',
      detail: outputFile.path,
      section: LogSection.generation,
      totalUnits: 100,
      weight: 18,
    );

    final result = await Subprocess.exec("ffmpeg", input,
        verbose: command.verbose,
        section: LogSection.generation,
        progressMode: SubprocessProgressMode.ffmpeg,
        expectedDuration: subtitles!.duration +
            (resolvedEndCard?.duration ?? Duration.zero) +
            const Duration(seconds: 2), onProgress: (update) {
      if (update.fraction != null) {
        generationProgress.updateTask(
          progressTask,
          completedUnits: update.fraction! * 100,
          detail: update.detail.isEmpty ? outputFile.path : update.detail,
        );
      }
    });

    int code = result.exitCode;

    if (code != 0) {
      generationProgress.completeTask(progressTask, detail: 'Render failed');
      throw FFmpegCommandException(
        message: "Something went wrong when generating the video. Exiting.",
        command: input,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
      );
    }
    generationProgress.completeTask(progressTask, detail: outputFile.path);

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
