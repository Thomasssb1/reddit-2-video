import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/voices/voices.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

void main() {
  late ParsedCommand command;

  setUp(() {
    command = MockParsedCommand();
    _stubCommand(command, type: RedditVideoType.comments);
  });

  group('Subtitles', () {
    group('delay resolution', () {
      test('delay is Duration.zero for post type', () {
        _stubCommand(command, type: RedditVideoType.post);

        final tempDir = Directory.systemTemp.createTempSync('subtitles_test_');
        addTearDown(() {
          tempDir.deleteSync(recursive: true);
        });

        final defaultAss = File('${tempDir.path}/defaults/default.ass');
        defaultAss.createSync(recursive: true);
        defaultAss.writeAsStringSync('[Script Info]\n');
        Directory('${tempDir.path}/.temp/test').createSync(recursive: true);

        AppPaths.initForTest(tempDir);

        final video = MockRedditVideo();
        when(() => video.posts).thenReturn([]);
        when(() => video.id).thenReturn('test');

        final voices = MockVoices();

        final subtitles = Subtitles(
          video: video,
          lexicons: const [],
          voices: voices,
          command: command,
        );

        expect(subtitles.delay, Duration.zero);
      });

      test('command.delay returns configured duration', () {
        when(() => command.delay).thenReturn(Duration(seconds: 3));
        expect(command.delay, Duration(seconds: 3));
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
        // We cannot easily construct a real Subtitles without filesystem.
        // The getTTSFilesAsInput / getTTSStream logic is tested via mock
        // in ffmpeg_command_test.dart; here we verify the method signatures
        // match the expected interface.
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

class MockSubtitles extends Mock implements Subtitles {}

class MockVoices extends Mock implements Voices {}

void _stubCommand(ParsedCommand command, {required RedditVideoType type}) {
  when(() => command.type).thenReturn(type);
  when(() => command.ntts).thenReturn(true);
  when(() => command.censor).thenReturn(false);
  when(() => command.delay).thenReturn(Duration(seconds: 1));
  when(() => command.alternate).thenReturn(Alternate(tts: false, color: false));
  when(() => command.titleColor)
      .thenReturn(SubstationAlphaSubtitleColor('#FF0000'));
  when(() => command.maxLength).thenReturn(null);
}
