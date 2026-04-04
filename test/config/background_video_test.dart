import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/exceptions/video_download_failed_exception.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/exceptions/invalid_video_url_exception.dart';
import 'package:reddit_2_video/utils/subprocess.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks.dart';

void main() {
  late BackgroundVideo backgroundVideo;
  late RedditVideo video;
  late ParsedCommand command;
  late File file;
  late Directory tempDir;
  Uri testVideoUrl =
      Uri.https("www.youtube.com", "watch", {"v": "tCDvOQI3pco"});

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('background_video_test_');
    AppPaths.initForTest(tempDir);
    backgroundVideo = MockBackgroundVideo();
    video = MockRedditVideo();
    command = MockParsedCommand();
    file = MockFile();
    when(() => command.verbose).thenReturn(false);
  });

  group("URI normalization", () {
    test("normalizes youtu.be url to www.youtube.com/watch?v=", () {
      final input = Uri.parse("https://youtu.be/tCDvOQI3pco");

      final normalized = BackgroundVideo.normalizeYoutubeUri(input);

      expect(normalized.authority, "www.youtube.com");
      expect(normalized.path, "/watch");
      expect(normalized.queryParameters["v"], "tCDvOQI3pco");
    });

    test("keeps default youtube watch url unchanged", () {
      final input = Uri.parse("https://www.youtube.com/watch?v=tCDvOQI3pco");

      final normalized = BackgroundVideo.normalizeYoutubeUri(input);

      expect(normalized.toString(), input.toString());
    });

    test("throws for invalid youtube urls", () {
      final input = Uri.parse("https://example.com/watch?v=tCDvOQI3pco");

      expect(
        () => BackgroundVideo.normalizeYoutubeUri(input),
        throwsA(isA<InvalidVideoUrl>()),
      );
    });
  });

  group("Constructor path resolution", () {
    test("resolves source path using AppPaths", () {
      final bg = BackgroundVideo(path: 'defaults/local.mp4');
      expect(bg.source.path, AppPaths.resolve('defaults/local.mp4').path);
    });
  });

  group("Cutting video to length", () {
    test("with no end card", () async {
      Duration duration = Duration(seconds: 10);

      when(() => command.endCard).thenAnswer((_) async => null);
      when(() => video.id).thenReturn("video_id");
      when(() => file.path).thenReturn(".temp/${video.id}/video.mp4");
      when(() => backgroundVideo.cutVideo(duration, video, command)).thenAnswer(
        (_) async => file,
      );

      File result = await backgroundVideo.cutVideo(duration, video, command);
      expect(result.path, file.path);
    });

    test("with an end card", () async {
      EndCard endCard = MockEndCard();
      when(() => endCard.duration).thenReturn(Duration(seconds: 1));
      Duration duration = Duration(seconds: 10);
      when(() => command.endCard).thenAnswer((_) async => endCard);
      when(() => video.id).thenReturn("video_id");
      when(() => file.path).thenReturn(".temp/${video.id}/video.mp4");
      when(() => backgroundVideo.cutVideo(duration, video, command))
          .thenAnswer((_) async => file);

      File result = await backgroundVideo.cutVideo(duration, video, command);
      expect(result.path, file.path);
    });
  });

  group("Download video with yt-dlp", () {
    test("downloads using process start when verbose is false", () async {
      String? executable;
      List<String>? arguments;
      final outputFile = AppPaths.resolve('defaults/tCDvOQI3pco.mp4');
      Subprocess.setStartForTest((exec, args,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        executable = exec;
        arguments = args;
        expect(mode, ProcessStartMode.normal);
        outputFile.createSync(recursive: true);
        return FakeProcess(exitCode: 0);
      });

      final result = await BackgroundVideo.downloadVideo(
        testVideoUrl,
        verbose: command.verbose,
      );

      expect(executable, 'yt-dlp');
      expect(arguments, isNotNull);
      expect(arguments, contains('-f'));
      expect(arguments, contains('bestvideo[ext=mp4]/best[ext=mp4]'));
      expect(arguments, contains(outputFile.path));
      expect(result.source.path, outputFile.path);
    });

    test("uses process start when verbose is true", () async {
      String? executable;
      List<String>? arguments;
      final outputFile = AppPaths.resolve('defaults/tCDvOQI3pco.mp4');
      when(() => command.verbose).thenReturn(true);
      Subprocess.setStartForTest((exec, args,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        executable = exec;
        arguments = args;
        outputFile.createSync(recursive: true);
        return FakeProcess(exitCode: 0);
      });

      final result = await BackgroundVideo.downloadVideo(
        testVideoUrl,
        verbose: command.verbose,
      );

      expect(executable, 'yt-dlp');
      expect(arguments, isNotNull);
      expect(arguments, contains('bestvideo[ext=mp4]/best[ext=mp4]'));
      expect(result.source.path, outputFile.path);
    });

    test("throws when yt-dlp exits with a non-zero code", () async {
      Subprocess.setStartForTest((_, __,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(exitCode: 1, err: 'boom');
      });
      expect(
        () => BackgroundVideo.downloadVideo(
          testVideoUrl,
        ),
        throwsA(isA<VideoDownloadFailedException>()),
      );
    });

    test("uses muxed format selector when muxed type requested", () async {
      List<String>? arguments;
      final outputFile = AppPaths.resolve('defaults/tCDvOQI3pco.mp4');
      Subprocess.setStartForTest((_, args,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        arguments = args;
        outputFile.createSync(recursive: true);
        return FakeProcess(exitCode: 0);
      });

      await BackgroundVideo.downloadVideo(
        testVideoUrl,
        videoType: VideoType.muxed,
        verbose: command.verbose,
      );

      expect(arguments, contains('best[ext=mp4]/best'));
    });
  });
  /*
  Fails on github actions -- need to investigate
  test("Downloading background video from source url", () async {
    BackgroundVideo downloadedVideo = await BackgroundVideo.downloadVideo(
        testVideoUrl, Directory.current.path);
    expect(downloadedVideo.source.existsSync(), true);
  });*/

  tearDown(() async {
    Subprocess.resetForTest();
    tempDir.deleteSync(recursive: true);
  });
}
