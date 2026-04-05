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
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/progress.dart';

import 'dart:io';

void main(
  List<String> args,
) async {
  Log? log;
  try {
    ParsedCommand command = ParsedCommand.parse(args);
    if (command.name == CommandType.defaultCommand) {
      await checkDependencies();
    }

    AppPaths.init();
    command.validateOutputFilesAvailable();
    log = await Log.fromFile();

    switch (command.name) {
      case CommandType.defaultCommand:
        generationProgress.start();
        logger.info(
          "Preparing background video.",
          section: LogSection.backgroundVideo,
        );
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
          if (command.type == RedditVideoType.comments) {
            final commentTask = generationProgress.createTask(
              title: 'Fetching Reddit comments',
              detail: 'Video ${index + 1}/${command.repeat}',
              section: LogSection.reddit,
              totalUnits: 1,
              weight: 2,
            );
            RedditPost post = video.posts.first;
            // TODO: add some sort of retry when there are < target comments
            await post.addComments(command);
            generationProgress.completeTask(commentTask,
                detail: 'Fetched comments for ${post.id}');
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
          final selectionTask = generationProgress.createTask(
            title: 'Selecting Reddit content',
            detail: 'Video ${i + 1}/${command.repeat}',
            section: LogSection.reddit,
            totalUnits: 1,
            weight: 2,
          );
          logger.info("Selecting Reddit content.", section: LogSection.reddit);
          RedditVideo video = await RedditVideo.parse(command, log);
          videos.add(video);
          generationProgress.completeTask(selectionTask,
              detail: 'Selected ${video.id}');
        }

        List<Future<RedditVideo>> generatedVideos =
            List.generate(command.repeat, (i) {
          return generateVideo(videos[i], i);
        }, growable: false);
        List<RedditVideo> finalVideos = await Future.wait(generatedVideos);

        for (int i = 1; i <= finalVideos.length; i++) {
          RedditVideo vid = finalVideos.elementAt(i - 1);
          File cutVideo = await backgroundVideo.cutVideo(
              vid.subtitles!.duration, vid, command);
          await vid.generate(command, backgroundVideo, cutVideo, i);
          log.add(vid);
        }
        generationProgress.stop();
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
        logger.error("No command found.", section: LogSection.setup);
    }
  } on Exception catch (e) {
    logger.error(e.toString(), section: LogSection.setup);
    exitCode = 1;
  } finally {
    generationProgress.stop();
    if (AppPaths.isDevMode) {
      logger.warning(
        "Running in dev mode, not clearing temporary files.",
        section: LogSection.setup,
      );
    } else {
      await log?.clearTemporaryFiles();
    }
  }
}
