import 'dart:io';

import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/exceptions/invalid_video_url_exception.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks.dart';

void main() {
  late BackgroundVideo backgroundVideo;
  late RedditVideo video;
  late ParsedCommand command;
  late File file;
  Uri testVideoUrl =
      Uri.https("www.youtube.com", "watch", {"v": "tCDvOQI3pco"});

  setUp(() {
    backgroundVideo = MockBackgroundVideo();
    video = MockRedditVideo();
    command = MockParsedCommand();
    file = MockFile();
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
      final input =
          Uri.parse("https://www.youtube.com/watch?v=tCDvOQI3pco");

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

  group("Cutting video to length", () {
    test("with no end card", () async {
      Duration duration = Duration(seconds: 10);

      when(() => command.endCard).thenReturn(null);
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
      when(() => command.endCard).thenReturn(endCard);
      when(() => video.id).thenReturn("video_id");
      when(() => file.path).thenReturn(".temp/${video.id}/video.mp4");
      when(() => backgroundVideo.cutVideo(duration, video, command))
          .thenAnswer((_) async => file);

      File result = await backgroundVideo.cutVideo(duration, video, command);
      expect(result.path, file.path);
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
    File file = File(
        "${Directory.current.path}/defaults/${testVideoUrl.queryParameters['v']}.mp4");
    if (file.existsSync()) {
      await file.delete();
    }
  });
}
