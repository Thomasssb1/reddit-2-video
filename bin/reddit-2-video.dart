import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/config/voice.dart';
import 'package:reddit_2_video/config/voices.dart';
import 'package:reddit_2_video/post/reddit_post.dart';
import 'package:reddit_2_video/post/reddit_video_type.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';

import 'dart:io';

void main(
  List<String> args,
) async {
  // TODO: check if everything is installed
  try {
    ParsedCommand command = ParsedCommand.parse(args);

    // Check that the dev flag is set whilst under development
    assert(command.isDev, true);

    switch (command.name) {
      case CommandType.defaultCommand:
        late BackgroundVideo backgroundVideo;
        if (command.video == null) {
          backgroundVideo = await BackgroundVideo.downloadVideo(
            BackgroundVideo.getDefaultVideoUrl(),
            command.prePath,
          );
        } else {
          backgroundVideo = BackgroundVideo(source: File(command.video!));
        }

        // Setup config files
        Log log = await Log.fromFile(command.prePath);
        List<Lexica> lexicons = Lexica.fromConfig(
            configPath: "/defaults/lexicons/lexemes.config.json",
            prePath: command.prePath);
        Lexica.update(
            "/defaults/lexicons/lexemes.config.json", lexicons, command);
        List<Voice> voices = Voices.fromFile(command);
        Voice initialVoice = Voices.find(voices, command.voice);

        Future<RedditVideo> generateVideo(RedditVideo video, int index) async {
          print("$index : ${video.id}");
          if (command.type == RedditVideoType.comments) {
            RedditPost post = video.posts.first;
            // TODO: add some sort of retry when there are < target comments
            await post.addComments(command);
          }

          Voices currentVoice = Voices(voices, initialVoice, command);
          Subtitles subtitles = Subtitles(
              video: video,
              lexicons: lexicons,
              voices: currentVoice,
              command: command);

          await subtitles.parse(command);
          video.subtitles = subtitles;

          return video;
        }

        List<RedditVideo> videos = [];
        for (int i = 0; i < command.repeat; i++) {
          RedditVideo video = await RedditVideo.parse(command, log);
          videos.add(video);
          print("$i - ${video.id}");
        }

        List<Future<RedditVideo?>> generatedVideos =
            List.generate(command.repeat, (i) {
          return generateVideo(videos[i], i).catchError((e) {
            print(e);
            return null;
          });
        }, growable: false);
        Iterable<RedditVideo> finalVideos =
            (await Future.wait(generatedVideos)).whereType<RedditVideo>();

        for (int i = 1; i <= finalVideos.length; i++) {
          print(i);
          RedditVideo vid = finalVideos.elementAt(i - 1);
          File cutVideo = await backgroundVideo.cutVideo(
              vid.subtitles!.duration, vid, command);
          await vid.generate(command, backgroundVideo, cutVideo, i);
          log.add(vid);
        }
      case CommandType.flush:
        Log log = await Log.fromFile(command.prePath);

        RedditPost? post;
        if (command.post != null) {
          post = await RedditPost.fromUrl(url: command.post!);
        }
        log.remove(post: post);

        await log.clearTemporaryFiles();
      case CommandType.install:
      // TODO: implement
      case CommandType.help:
        command.printHelp();
      case null:
        print("No command found.");
    }
  } on Exception catch (e) {
    print(e);
  }
}
