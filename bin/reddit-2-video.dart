import 'dart:io';

import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/ffmpeg/ffmpeg_command.dart';
import 'package:reddit_2_video/post/reddit_post.dart';
import 'package:reddit_2_video/post/reddit_video_type.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';

void main(
  List<String> args,
) async {
  // TODO: check if everything is installed
  try {
    ParsedCommand command = ParsedCommand.parse(args);

    // Check that the dev flag is set whilst under development
    assert(command.isDev, true);

    switch (command.name) {
      case Command.defaultCommand:
        BackgroundVideo backgroundVideo = BackgroundVideo(
          url: Uri.parse("https://www.youtube.com/watch?v=n_Dv4JMiwK8"),
          prePath: command.prePath,
        );

        await backgroundVideo.downloadVideo();

        Log log = await Log.fromFile(command.prePath);

        for (int i = 0; i < command.repeat; ++i) {
          RedditVideo video = await RedditVideo.parse(command, log);

          print("Video setup complete");

          if (command.type == RedditVideoType.comments) {
            RedditPost post = video.posts.first;
            post.addComments(command);
          }

          Subtitles subtitles = Subtitles(video: video, command: command);
          print("Subtitles setup complete");

          await subtitles.parse(command);

          await backgroundVideo.cutVideo(subtitles.duration, video, command);

          await video.generate(command, subtitles, backgroundVideo);
        }
      case Command.flush:
        Log log = await Log.fromFile(command.prePath);

        RedditPost? post;
        if (command.post != null) {
          post = await RedditPost.fromUrl(url: command.post!);
        }
        log.remove(post);
      case Command.install:
      // TODO: implement
      case Command.help:
        command.printHelp();
      case null:
        print("No command found.");
    }
  } on Exception catch (e) {
    print(e);
  }
}
