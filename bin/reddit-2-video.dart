import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/config/voices/voice.dart';
import 'package:reddit_2_video/config/voices/voices.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/cmd/install.dart';

import 'dart:io';

void main(
  List<String> args,
) async {
  await checkDependencies();
  ParsedCommand command = ParsedCommand.parse(args);
  AppPaths.init(isDev: command.isDev);
  Log log = await Log.fromFile();
  try {
    // Check that the dev flag is set whilst under development
    assert(command.isDev, true);

    switch (command.name) {
      case CommandType.defaultCommand:
        late BackgroundVideo backgroundVideo;
        if (command.video == null) {
          backgroundVideo = await BackgroundVideo.downloadVideo(
            BackgroundVideo.getDefaultVideoUrl(),
            verbose: command.verbose,
          );
        } else {
          backgroundVideo = BackgroundVideo(path: command.video!);
        }

        // Setup config files
        List<Lexica> lexicons = Lexica.fromConfig(
            configPath: 'defaults/lexicons/lexemes.config.json');
        Lexica.update("defaults/lexicons/lexemes.config.json", lexicons,
            verbose: command.verbose);
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

        List<Future<RedditVideo>> generatedVideos =
            List.generate(command.repeat, (i) {
          return generateVideo(videos[i], i);
        }, growable: false);
        List<RedditVideo> finalVideos = await Future.wait(generatedVideos);

        for (int i = 1; i <= finalVideos.length; i++) {
          print(i);
          RedditVideo vid = finalVideos.elementAt(i - 1);
          File cutVideo = await backgroundVideo.cutVideo(
              vid.subtitles!.duration, vid, command);
          await vid.generate(command, backgroundVideo, cutVideo, i);
          log.add(vid);
        }
        break;
      case CommandType.flush:
        RedditPost? post;
        if (command.post != null) {
          post = await RedditPost.fromUrl(url: command.post!);
        }
        log.remove(post: post);

        await log.clearTemporaryFiles();
        break;
      case CommandType.install:
        await runInstallCommand();
        break;
      case CommandType.help:
        command.printHelp();
        break;
      case null:
        print("No command found.");
    }
  } on Exception catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  } finally {
    if (command.isDev) {
      print("Running in dev mode, not clearing temporary files.");
    } else {
      await log.clearTemporaryFiles();
    }
  }
}
