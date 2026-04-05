import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/ffmpeg/ffmpeg_command.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  late ParsedCommand command;
  late BackgroundVideo backgroundVideo;
  late Subtitles subtitles;
  late File cutVideo;

  setUp(() {
    command = MockParsedCommand();
    backgroundVideo = MockBackgroundVideo();
    subtitles = MockSubtitles();
    cutVideo = MockFile();

    when(() => command.verbose).thenReturn(false);
    when(() => command.override).thenReturn(false);
    when(() => command.horror).thenReturn(false);
    when(() => command.framerate).thenReturn(FPS.fps45);
    when(() => command.output).thenReturn('output.mp4');
    when(() => command.fileType).thenReturn(FileType.mp4);
    when(() => command.repeat).thenReturn(1);

    when(() => backgroundVideo.position).thenReturn(0);
    when(() => cutVideo.path).thenReturn('input.mp4');

    when(() => subtitles.getTTSFilesAsInput()).thenReturn([]);
    when(() => subtitles.getTTSStream(any())).thenReturn(['[1:a]', '[2:a]']);
    when(() => subtitles.assFile).thenReturn(File('subtitles.ass'));
    when(() => subtitles.duration).thenReturn(Duration(seconds: 5));
    when(() => subtitles.position = any<int>()).thenReturn(0);
    when(() => subtitles.position).thenReturn(1);
  });

  String _filterFrom(List<String> command) {
    final i = command.indexOf('-filter_complex');
    return command[i + 1];
  }

  group('FFmpegCommand', () {
    group('inputFiles', () {
      test('includes cut video as first input', () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final inputs = ffCmd.inputFiles(cutVideo);

        expect(inputs.take(2), ['-i', 'input.mp4']);
      });

      test('sets subtitles.position to first available stream index', () {
        when(() => backgroundVideo.position).thenReturn(2);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        ffCmd.inputFiles(cutVideo);

        verify(() => subtitles.position = 3).called(1);
      });

      test('appends subtitle tts inputs', () {
        when(() => subtitles.getTTSFilesAsInput())
            .thenReturn(['-i', 'tts-1.mp3', '-i', 'tts-2.mp3']);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final inputs = ffCmd.inputFiles(cutVideo);

        expect(
            inputs, containsAllInOrder(['-i', 'tts-1.mp3', '-i', 'tts-2.mp3']));
      });

      test(
          'includes empty noise, music and end card in order and assigns positions',
          () {
        final noise = MockEmptyNoise();
        final noiseFile = MockFile();
        when(() => noiseFile.path).thenReturn('noise.wav');
        when(() => noise.path).thenReturn(noiseFile);
        when(() => noise.position = any<int?>()).thenReturn(null);

        final music = MockMusic();
        final musicFile = MockFile();
        when(() => musicFile.path).thenReturn('music.mp3');
        when(() => music.path).thenReturn(musicFile);
        when(() => music.position = any<int?>()).thenReturn(null);

        final endCard = MockEndCard();
        final endCardFile = MockFile();
        when(() => endCardFile.path).thenReturn('endcard.mp4');
        when(() => endCard.path).thenReturn(endCardFile);
        when(() => endCard.position = any<int?>()).thenReturn(null);

        when(() => backgroundVideo.position).thenReturn(2);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
          emptyNoise: noise,
          music: music,
          endCard: endCard,
        );

        final inputs = ffCmd.inputFiles(cutVideo);

        expect(
          inputs,
          containsAllInOrder([
            '-i',
            'input.mp4',
            '-i',
            'noise.wav',
            '-i',
            'music.mp3',
            '-i',
            'endcard.mp4',
          ]),
        );
        verify(() => noise.position = 3).called(1);
        verify(() => music.position = 4).called(1);
        verify(() => endCard.position = 5).called(1);
        verify(() => subtitles.position = 6).called(1);
      });
    });

    group('generate', () {
      test(
          'outputs provided filename when extension is present and repeat is 1',
          () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);

        expect(result.last, 'output.mp4');
      });

      test('defaults to final filename when output has no extension', () {
        when(() => command.output).thenReturn('output');

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);

        expect(result.last, 'final.mp4');
      });

      test('uses fileType when output extension conflicts', () {
        when(() => command.output).thenReturn('output.avi');
        when(() => command.fileType).thenReturn(FileType.mp4);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);

        expect(result.last, 'output.mp4');
      });

      test('adds repeat index suffix when repeat is greater than 1', () {
        when(() => command.repeat).thenReturn(2);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 7);

        expect(result.last, 'output-7.mp4');
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

      test('includes -n flag when override is false', () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);

        expect(result, contains('-n'));
      });

      test('includes -nostdin to prevent ffmpeg interactive prompts', () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);

        expect(result, contains('-nostdin'));
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

      test('contains map and filter_complex flags', () {
        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);

        expect(result,
            containsAllInOrder(['-map', '[final_a]', '-filter_complex']));
      });

      test('includes subtitle path and fps in filter', () {
        when(() => command.framerate).thenReturn(FPS.fps60);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        final filter = _filterFrom(result);

        expect(filter, contains("subtitles='subtitles.ass'"));
        expect(filter, contains(',fps=60'));
      });

      test('includes horror rubberband filter when horror is true', () {
        when(() => command.horror).thenReturn(true);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        final filter = _filterFrom(result);

        expect(filter, contains('rubberband=pitch=0.8'));
      });

      test('adds music merge section when music input has position', () {
        final music = MockMusic();
        final musicFile = MockFile();
        when(() => musicFile.path).thenReturn('music.mp3');
        when(() => music.path).thenReturn(musicFile);
        when(() => music.position = any<int?>()).thenReturn(null);
        when(() => music.position).thenReturn(4);
        when(() => music.volume).thenReturn(0.3);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
          music: music,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        final filter = _filterFrom(result);

        expect(filter, contains('[4:a]volume=0.3'));
        expect(filter, contains('[0a][1a]amerge'));
      });

      test('adds endcard overlay section when endcard position is set', () {
        final endCard = MockEndCard();
        final endCardFile = MockFile();
        when(() => endCardFile.path).thenReturn('endcard.mp4');
        when(() => endCard.path).thenReturn(endCardFile);
        when(() => endCard.position = any<int?>()).thenReturn(null);
        when(() => endCard.position).thenReturn(6);
        when(() => endCard.duration).thenReturn(Duration(seconds: 4));
        when(() => subtitles.duration).thenReturn(Duration(seconds: 5));

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
          endCard: endCard,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        final filter = _filterFrom(result);

        expect(filter, contains('[6:v]setpts=PTS-STARTPTS+6/TB[gif]'));
        expect(filter, contains("between(t,6, 11)"));
      });

      test('uses base video section when endcard position is null', () {
        final endCard = MockEndCard();
        final endCardFile = MockFile();
        when(() => endCardFile.path).thenReturn('endcard.mp4');
        when(() => endCard.path).thenReturn(endCardFile);
        when(() => endCard.position = any<int?>()).thenReturn(null);
        when(() => endCard.position).thenReturn(null);

        final ffCmd = FFmpegCommand(
          subtitles: subtitles,
          backgroundVideo: backgroundVideo,
          endCard: endCard,
        );

        final result = ffCmd.generate(command, cutVideo, 1);
        final filter = _filterFrom(result);

        expect(filter, contains('[0:v]crop=585:1080'));
      });
    });
  });
}
