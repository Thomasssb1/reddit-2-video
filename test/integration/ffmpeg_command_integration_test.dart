import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/ffmpeg/ffmpeg_command.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
import 'package:test/test.dart';

import '../mocks.dart';
import '../test_helper.dart';

void main() {
  late Directory tempDir;

  group('FFmpeg command integration', () {
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ffmpeg_integration_');
      AppPaths.initForTest(tempDir);
      useRealSubprocesses();
    });

    tearDown(() {
      Subprocess.resetForTest();
      tempDir.deleteSync(recursive: true);
    });

    test('FFmpegCommand.generate produces a runnable ffmpeg command', () async {
      final cutVideo = File('${tempDir.path}/cut.mp4');
      final tts = File('${tempDir.path}/tts.mp3');
      final ass = File('${tempDir.path}/subtitles.ass');

      await createDummyVideo(cutVideo.path, size: '1080x1920');
      await createDummyAudio(tts.path);
      ass.writeAsStringSync('''
[Script Info]
ScriptType: v4.00+
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,32,&H00FFFFFF,&H0000FFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,1,0,2,10,10,10,1
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:00:00.80,Default,,0,0,0,,Hello
''');

      final subtitles = MockSubtitles();
      when(() => subtitles.getTTSFilesAsInput()).thenReturn(['-i', tts.path]);
      when(() => subtitles.getTTSStream(any())).thenReturn(['[1:a]']);
      when(() => subtitles.assFile).thenReturn(ass);
      when(() => subtitles.duration).thenReturn(const Duration(seconds: 1));
      when(() => subtitles.position = any<int>()).thenReturn(0);

      final command = MockParsedCommand();
      when(() => command.override).thenReturn(true);
      when(() => command.verbose).thenReturn(false);
      when(() => command.horror).thenReturn(false);
      when(() => command.framerate).thenReturn(FPS.fps30);
      when(() => command.output).thenReturn('output.mp4');
      when(() => command.fileType).thenReturn(FileType.mp4);
      when(() => command.repeat).thenReturn(1);

      final ffmpegCommand = FFmpegCommand(
        subtitles: subtitles,
        backgroundVideo: BackgroundVideo.fromFile(source: cutVideo),
      );

      final args = ffmpegCommand.generate(command, cutVideo, 1);
      final result = await Subprocess.exec('ffmpeg', args);

      expect(result.exitCode, 0, reason: result.stderr);
      expect(File('${tempDir.path}/output.mp4').existsSync(), isTrue);
    });
  });
}
