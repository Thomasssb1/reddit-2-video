import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
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

    test('splitVideo creates real segment files with reset timestamps',
        () async {
      final input = File(p.join(tempDir.path, 'clip.mp4'));
      await createDummyVideo(input.path, seconds: 65, withAudio: true);

      final segments = await splitVideo(input.path, 'mp4', 0);
      final durations = <double>[];

      expect(segments, hasLength(2));
      expect(
        segments.map((file) => p.basename(file.path)).toList(),
        orderedEquals(<String>['clip000.mp4', 'clip001.mp4']),
      );

      for (final segment in segments) {
        expect(segment.existsSync(), isTrue);

        final probeResult = await Process.run(resolveExecutable('ffprobe'), [
          '-v',
          'error',
          '-show_entries',
          'format=start_time,duration',
          '-of',
          'json',
          segment.path,
        ]);

        expect(probeResult.exitCode, 0, reason: probeResult.stderr.toString());
        final json =
            jsonDecode(probeResult.stdout.toString()) as Map<String, dynamic>;
        final format = json['format'] as Map<String, dynamic>;
        final startTime = double.parse(format['start_time'].toString());
        final duration = double.parse(format['duration'].toString());

        expect(startTime, closeTo(0, 0.1));
        durations.add(duration);
      }

      expect(durations.first, closeTo(60, 1.0));
      expect(durations.last, lessThan(10));
      expect(durations.last, closeTo(5, 1.0));
    });
  });
}
