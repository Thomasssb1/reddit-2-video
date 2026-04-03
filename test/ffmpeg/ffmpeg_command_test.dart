import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/config/music.dart';
import 'package:reddit_2_video/ffmpeg/ffmpeg_command.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:test/test.dart';

import '../mocks.dart';

class MockSubtitles extends Mock implements Subtitles {}

class MockEmptyNoise extends Mock implements EmptyNoise {}

class MockMusic extends Mock implements Music {}

void main() {
  late ParsedCommand command;
  late BackgroundVideo backgroundVideo;
  late Subtitles subtitles;
  late EmptyNoise emptyNoise;
  late File cutVideo;

  setUp(() {
    command = MockParsedCommand();
    backgroundVideo = MockBackgroundVideo();
    subtitles = MockSubtitles();
    emptyNoise = MockEmptyNoise();
    cutVideo = MockFile();

    when(() => command.verbose).thenReturn(false);
    when(() => command.override).thenReturn(false);
    when(() => command.horror).thenReturn(false);
    when(() => command.framerate).thenReturn(FPS.fps45);
    when(() => command.output).thenReturn('output');
    when(() => command.fileType).thenReturn(FileType.mp4);
    when(() => command.repeat).thenReturn(1);
    when(() => backgroundVideo.position).thenReturn(0);
    when(() => cutVideo.path).thenReturn('input.mp4');
    when(() => subtitles.getTTSFilesAsInput()).thenReturn([]);
    when(() => subtitles.getTTSStream(any())).thenReturn([]);
    when(() => subtitles.assFile).thenReturn(File('subtitles.ass'));
    when(() => subtitles.duration).thenReturn(Duration(seconds: 5));
    when(() => subtitles.position = any<int>()).thenReturn(0);
    when(() => subtitles.position).thenReturn(1);
  });

  group('FFmpegCommand', () {
    group('inputFiles', () {
      test('includes cut video as first input', () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final inputs = ffCmd.inputFiles(cutVideo);
        expect(inputs, containsAllInOrder(['-i', 'input.mp4']));
      });

      test('includes empty noise path when EmptyNoise provided', () {
        final mockNoise = MockEmptyNoise();
        final noiseFile = MockFile();
        when(() => noiseFile.path).thenReturn('noise.wav');
        when(() => mockNoise.path).thenReturn(noiseFile);
        when(() => mockNoise.position).thenReturn(null);
        when(() => mockNoise.position = any<int>()).thenReturn(0);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
          emptyNoise: mockNoise,
        );

        final inputs = ffCmd.inputFiles(cutVideo);
        expect(inputs, contains('noise.wav'));
      });
    });

    group('generate', () {
      test(
          'output filename defaults to "final" suffix with .mp4 when no extension and repeat is 1',
          () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        expect(result.last, 'outputfinal.mp4');
      });

      test('includes -y flag when override is true', () {
        when(() => command.override).thenReturn(true);
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        expect(result, contains('-y'));
      });

      test('includes quiet flag when verbose is false', () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        expect(result, containsAllInOrder(['-loglevel', 'quiet']));
      });

      test('does not include quiet flag when verbose is true', () {
        when(() => command.verbose).thenReturn(true);
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        expect(result, isNot(contains('-loglevel')));
      });
    });
  });
}
