import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late ParsedCommand command;

  Directory _initSubtitlesTestRoot() {
    final tempDir = Directory.systemTemp.createTempSync('subtitles_test_');
    final defaultAss = File('${tempDir.path}/defaults/default.ass');
    defaultAss.createSync(recursive: true);
    defaultAss.writeAsStringSync('[Script Info]\n');
    Directory('${tempDir.path}/.temp/test').createSync(recursive: true);
    AppPaths.initForTest(tempDir);
    return tempDir;
  }

  void _stubCommand(ParsedCommand command, {required RedditVideoType type}) {
    when(() => command.type).thenReturn(type);
    when(() => command.ntts).thenReturn(true);
    when(() => command.censor).thenReturn(false);
    when(() => command.delay).thenReturn(Duration(seconds: 1));
    when(() => command.alternate)
        .thenReturn(Alternate(tts: false, color: false));
    when(() => command.titleColor)
        .thenReturn(SubstationAlphaSubtitleColor('#FF0000'));
    when(() => command.maxLength).thenReturn(null);
  }

  setUp(() {
    command = MockParsedCommand();
    _stubCommand(command, type: RedditVideoType.comments);
  });

  group('Subtitles', () {
    group('constructor', () {
      test('delay is Duration.zero for post type', () {
        _stubCommand(command, type: RedditVideoType.post);
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: MockVoices(),
          command: command,
        );

        expect(subtitles.delay, Duration.zero);
      });

      test('copies command flags and uses command delay for non-post type', () {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));

        when(() => command.ntts).thenReturn(false);
        when(() => command.censor).thenReturn(true);
        when(() => command.delay).thenReturn(Duration(seconds: 3));
        when(() => command.alternate)
            .thenReturn(Alternate(tts: true, color: true));
        when(() => command.titleColor)
            .thenReturn(SubstationAlphaSubtitleColor('#00FF00'));

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: MockVoices(),
          command: command,
        );

        expect(subtitles.ntts, isFalse);
        expect(subtitles.censor, isTrue);
        expect(subtitles.delay, Duration(seconds: 3));
        expect(subtitles.alternate.tts, isTrue);
        expect(subtitles.alternate.color, isTrue);
        expect(
          subtitles.titleColor.toString(),
          SubstationAlphaSubtitleColor('#00FF00').toString(),
        );
      });
    });

    group('parse without external processes', () {
      test(
          'keeps duration zero when title/body/comments are empty after cleanup',
          () async {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final post = MockRedditPost();
        when(() => post.title).thenReturn('😀😀');
        when(() => post.body).thenReturn('');
        when(() => post.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: MockVoices(),
          command: command,
        );

        await subtitles.parse(command);

        expect(subtitles.duration, Duration.zero);
      });

      test('adds per-post delay in multi mode even when no text is parsed',
          () async {
        _stubCommand(command, type: RedditVideoType.multi);
        when(() => command.delay).thenReturn(Duration(seconds: 2));

        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final post1 = MockRedditPost();
        when(() => post1.title).thenReturn('');
        when(() => post1.body).thenReturn('');
        when(() => post1.comments).thenReturn([]);

        final post2 = MockRedditPost();
        when(() => post2.title).thenReturn('');
        when(() => post2.body).thenReturn('');
        when(() => post2.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post1, post2]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: MockVoices(),
          command: command,
        );

        await subtitles.parse(command);

        expect(subtitles.duration, Duration(seconds: 4));
      });
    });

    group('maxLength via ParsedCommand', () {
      test('maxLength is null when not set', () {
        when(() => command.maxLength).thenReturn(null);
        expect(command.maxLength, isNull);
      });

      test('maxLength returns Duration when set', () {
        when(() => command.maxLength).thenReturn(Duration(seconds: 60));
        expect(command.maxLength, Duration(seconds: 60));
      });
    });

    group('getTTSFilesAsInput', () {
      test('returns empty list when no subtitles parsed', () {
        final mockSubtitles = MockSubtitles();
        when(() => mockSubtitles.getTTSFilesAsInput()).thenReturn([]);
        expect(mockSubtitles.getTTSFilesAsInput(), isEmpty);
      });
    });

    group('getTTSStream', () {
      test('returns stream list for given emptyNoise', () {
        final mockSubtitles = MockSubtitles();
        when(() => mockSubtitles.getTTSStream(null)).thenReturn([]);
        expect(mockSubtitles.getTTSStream(null), isEmpty);
      });
    });
  });
}
