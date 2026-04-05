import 'dart:io';

import 'package:reddit_2_video/ffmpeg/splitter.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  late Directory tempDir;

  group('Splitter integration', () {
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('splitter_integration_');
      useRealSubprocesses();
    });

    tearDown(() {
      Subprocess.resetForTest();
      tempDir.deleteSync(recursive: true);
    });

    test('splitVideo creates real segment files with ffmpeg', () async {
      final input = File('${tempDir.path}/clip.mp4');
      await createDummyVideo(input.path);

      final segments = await splitVideo(input.path, 'mp4', 0);

      expect(segments, isNotEmpty);
      expect(segments.first.existsSync(), isTrue);
      expect(segments.first.path, contains('clip'));
    });
  });
}
