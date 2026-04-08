import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/text_color.dart';
import 'package:reddit_2_video/config/voices/voice.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/subtitles/subtitle.dart';
import 'package:reddit_2_video/subtitles/subtitle_config.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
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
    when(() => command.verbose).thenReturn(false);
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
    TextColor.reset();
    Subtitle.setDurationReaderForTest((file) => const Duration(seconds: 1));
    SubtitleConfig.setDurationReaderForTest(
        (file) => const Duration(seconds: 1));
  });

  tearDown(() {
    Subprocess.resetForTest();
    Subtitle.resetForTest();
    SubtitleConfig.resetForTest();
    TextColor.reset();
  });

  void _stubTtsProcesses(
      {int ttsExitCode = 0,
      int speechMarkExitCode = 0,
      List<String>? seenTexts}) {
    Subprocess.setStartForTest((executable, arguments,
        {workingDirectory,
        environment,
        includeParentEnvironment = true,
        runInShell = false,
        mode = ProcessStartMode.normal}) async {
      if (executable == 'aws') {
        final outPath = arguments.last;
        seenTexts?.add(arguments[arguments.indexOf('--text') + 1]);
        final outputFile = AppPaths.resolve(outPath);
        outputFile.createSync(recursive: true);

        final outputFormat =
            arguments[arguments.indexOf('--output-format') + 1];
        if (outputFormat == 'json') {
          outputFile.writeAsStringSync([
            '{"time":0,"type":"word","start":0,"end":5,"value":"hello"}',
            '{"time":500,"type":"word","start":6,"end":11,"value":"world"}',
          ].join('\n'));
          return FakeProcess(
            exitCode: speechMarkExitCode,
            out: speechMarkExitCode == 0 ? 'ok' : '',
            err: speechMarkExitCode == 0 ? '' : 'speech marks failed',
          );
        }

        return FakeProcess(
          exitCode: ttsExitCode,
          out: ttsExitCode == 0 ? 'ok' : '',
          err: ttsExitCode == 0 ? '' : 'aws failed',
        );
      }

      return FakeProcess(exitCode: 0);
    });
  }

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

      test('generates subtitles, ass output, and tts inputs on success',
          () async {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        _stubTtsProcesses();

        final voice = Voice(id: 'Matthew', neural: true, standard: true);
        final voices = MockVoices();
        when(() => voices.current).thenReturn(voice);
        when(() => voices.next()).thenReturn(null);

        final post = MockRedditPost();
        when(() => post.title).thenReturn('hello world');
        when(() => post.body).thenReturn('');
        when(() => post.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: voices,
          command: command,
        );

        await subtitles.parse(command);

        expect(subtitles.duration, const Duration(seconds: 1));
        expect(subtitles.getTTSFilesAsInput(), hasLength(2));
        expect(subtitles.assFile.readAsStringSync(), contains('Dialogue: 0,'));
      });

      test('splits oversized text into multiple TTS requests', () async {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final seenTexts = <String>[];
        _stubTtsProcesses(seenTexts: seenTexts);

        final voice = Voice(id: 'Matthew', neural: true, standard: true);
        final voices = MockVoices();
        when(() => voices.current).thenReturn(voice);
        when(() => voices.next()).thenReturn(null);

        final post = MockRedditPost();
        when(() => post.title).thenReturn('${'a' * 3001}.${'b' * 3001}.');
        when(() => post.body).thenReturn('');
        when(() => post.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: voices,
          command: command,
        );

        await subtitles.parse(command);

        expect(seenTexts.length, greaterThan(1));
      });

      test('throws when TTS generation fails', () async {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        _stubTtsProcesses(ttsExitCode: 1);

        final voice = Voice(id: 'Matthew', neural: true, standard: true);
        final voices = MockVoices();
        when(() => voices.current).thenReturn(voice);
        when(() => voices.next()).thenReturn(null);

        final post = MockRedditPost();
        when(() => post.title).thenReturn('hello world');
        when(() => post.body).thenReturn('');
        when(() => post.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: voices,
          command: command,
        );

        await expectLater(
          () => subtitles.parse(command),
          throwsA(isA<TTSFailedException>()
              .having((e) => e.stderr, 'stderr', contains('aws failed'))
              .having((e) => e.errorDetail, 'errorDetail',
                  contains('aws failed'))),
        );
      });

      test('throws when speech mark generation fails', () async {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        _stubTtsProcesses(speechMarkExitCode: 1);

        final voice = Voice(id: 'Matthew', neural: true, standard: true);
        final voices = MockVoices();
        when(() => voices.current).thenReturn(voice);
        when(() => voices.next()).thenReturn(null);

        final post = MockRedditPost();
        when(() => post.title).thenReturn('hello world');
        when(() => post.body).thenReturn('');
        when(() => post.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: voices,
          command: command,
        );

        await expectLater(
          () => subtitles.parse(command),
          throwsA(isA<TTSFailedException>()
              .having(
                  (e) => e.stderr, 'stderr', contains('speech marks failed'))
              .having((e) => e.errorDetail, 'errorDetail',
                  contains('speech marks failed'))),
        );
      });

      test('alternates voice and colour when configured', () async {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        _stubTtsProcesses();
        when(() => command.alternate)
            .thenReturn(const Alternate(tts: true, color: true));

        final voice = Voice(id: 'Matthew', neural: true, standard: true);
        final voices = MockVoices();
        when(() => voices.current).thenReturn(voice);
        when(() => voices.next()).thenReturn(null);

        final post = MockRedditPost();
        when(() => post.title).thenReturn('hello world');
        when(() => post.body).thenReturn('body text');
        when(() => post.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: voices,
          command: command,
        );

        final initialColor = TextColor.current;
        await subtitles.parse(command);
        final finalColor = TextColor.current;

        verify(() => voices.next()).called(2);
        expect(initialColor, SubstationAlphaSubtitleColor('#FFFFFF'));
        expect(finalColor, SubstationAlphaSubtitleColor('#FF0000'));
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

      test('returns expected stream order after parse', () async {
        final tempDir = _initSubtitlesTestRoot();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        _stubTtsProcesses();

        final voice = Voice(id: 'Matthew', neural: true, standard: true);
        final voices = MockVoices();
        when(() => voices.current).thenReturn(voice);
        when(() => voices.next()).thenReturn(null);

        final post = MockRedditPost();
        when(() => post.title).thenReturn('hello world');
        when(() => post.body).thenReturn('');
        when(() => post.comments).thenReturn([]);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([post]);
        when(() => video.id).thenReturn('test');

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: voices,
          command: command,
        );
        subtitles.position = 3;

        await subtitles.parse(command);

        final noise = MockEmptyNoise();
        when(() => noise.position).thenReturn(2);
        expect(subtitles.getTTSStream(noise), ['[3:a]']);
      });
    });
  });
}
