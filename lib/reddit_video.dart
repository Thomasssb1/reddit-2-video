import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/ffmpeg/ffmpeg_command.dart';
import 'package:reddit_2_video/post/reddit_post.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:http/http.dart' as http;
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'post/reddit_video_type.dart';
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
  List<String> inputStreams = [];

  RedditVideo({
    required this.posts,
    required this.videoType,
    required String prePath,
  }) {
    _generateFolderStructure("$prePath/.temp/$id/");
  }

  RedditVideo.single({
    required RedditPost post,
    required RedditVideoType videoType,
    required String prePath,
  }) : this(posts: [post], videoType: videoType, prePath: prePath);

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
      RedditVideo video = RedditVideo.single(
          post: post, videoType: command.type, prePath: command.prePath);

      if (log.contains(video.posts.first)) {
        throw PostAlreadyGeneratedException(
            message:
                "The link provided in --subreddit has already had a video been generated previously.",
            help:
                "If you have already generated a video for this post you can remove this from the log by running reddit-2-video flush with the -p argument supplied.");
      }
      return video;
    }

    // create a new link that also contains the sort
    Uri subredditLink = Uri.https(
        "reddit.com", "/r/${command.subreddit}/${command.sort.name}.json");

    http.Response response = await http.get(subredditLink);

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
              await RedditPost.fromId(subreddit: subreddit, id: id);

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
        return RedditVideo.single(
            post: postData.first,
            videoType: command.type,
            prePath: command.prePath);
      }

      // if the user wants to confirm the post and the subreddit arg is not a link
      if (command.postConfirmation) {
        // iterate through each post collected previously
        for (final post in postData) {
          // output relevant information
          print("\x1b[4m${post.title}\x1b[0m\n");
          print(
              "\x1b[32mUpvotes: ${post.upvotes}     \x1b[33mComments: ${post.commentCount} \x1b[0m\n");
          print(
              "Created: ${post.created}, ${post.spoiler ? 'This post \x1b[31mis\x1b[0m marked as a spoiler' : ''}\n");
          if (post.hasMedia) {
            print("Media: ${post.hasMedia}\n");
          }
          if (command.nsfw) {
            print(
                "This post is${post.nsfw ? '' : ' \x1b[31mnot\x1b[0m'} marked as NSFW.");
          }
          print(
              "\x1b[4mPost ${postData.indexOf(post) + 1}/${postData.length}.\x1b[0m");
          print(
              "Do you want to see the body of the post? [\x1b[32my\x1b[0m/\x1b[31mN\x1b[0m] ");
          // read the cli for what the user entered
          String showBody = stdin.readLineSync() ?? 'n';
          // if the user entered yes
          if (showBody.toLowerCase() == 'y') {
            print(post.body);
          }
          print(
              "Do you want to generate a video for this post? [\x1b[32my\x1b[0m/\x1b[31mN\x1b[0m] ");
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
      return RedditVideo(
          posts: postData, videoType: command.type, prePath: command.prePath);
    } else {
      throw RedditApiException(
          message:
              "An error occurred whilst trying to fetch the subreddit data. Try again later.",
          statusCode: response.statusCode);
    }
  }

  Future<void> generate(ParsedCommand command, Subtitles subtitles,
      BackgroundVideo backgroundVideo) async {
    EmptyNoise? emptyNoise;
    if (command.type != RedditVideoType.post) {
      emptyNoise = EmptyNoise(prePath: command.prePath);
    }

    FFmpegCommand ffmpegCommand = FFmpegCommand(
      subtitles: subtitles,
      backgroundVideo: backgroundVideo,
      emptyNoise: emptyNoise,
      music: command.music,
      endCard: command.endCard,
    );

    List<String> input = ffmpegCommand.generate(command);
    print(input);

    final process = await Process.start("ffmpeg", input);
    if (command.verbose) {
      process.stderr.transform(utf8.decoder).listen((data) {
        stdout.write(data);
      });
    }
    stdin.pipe(process.stdin);
    int code = await process.exitCode;
    if (code != 0) {
      throw FFmpegCommandException(
          message: "Something went wrong when generating the video. Exiting.",
          command: input);
    }
  }

  Future<void> _generateFolderStructure(String path) async {
    Directory(path).createSync(recursive: true);
  }

  String get id => posts.map((e) => e.id).join("-");
}
