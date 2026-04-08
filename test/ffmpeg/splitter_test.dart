import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/ffmpeg/splitter.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('FFmpeg Splitter Tests', () {
    late Directory tempDir;
    late File mockVideo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('splitter_test_');
      mockVideo = File('${tempDir.path}/test_output.mp4')..createSync();
    });

    tearDown(() {
      Subprocess.resetForTest();
      tempDir.deleteSync(recursive: true);
    });

    test('Throws FFmpegCommandException when splitting fails', () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(exitCode: 1, err: 'split failed');
      });

      await expectLater(
        () => splitVideo(mockVideo.path, 'mp4', 0),
        throwsA(isA<FFmpegCommandException>()
            .having((e) => e.command, 'command', isNotEmpty)
            .having((e) => e.errorDetail, 'errorDetail',
                contains('split failed'))),
      );
    });

    test('Successfully returns generated matching segments', () async {
      late List<String> capturedArguments;
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        capturedArguments = arguments;
        File(p.join(tempDir.path, 'test_output000.mp4')).writeAsStringSync('');
        return FakeProcess(exitCode: 0);
      });

      final segments = await splitVideo(mockVideo.path, 'mp4', 0);

      expect(segments, isNotEmpty);
      expect(segments.first.existsSync(), isTrue);
      expect(segments.first.path, p.join(tempDir.path, 'test_output000.mp4'));
      expect(
        capturedArguments,
        containsAllInOrder(<String>[
          '-reset_timestamps',
          '1',
          '-segment_time',
          '00:00:55',
          p.join(tempDir.path, 'test_output%03d.mp4'),
        ]),
      );
    });

    test('Returns only matching segments in a deterministic order', () async {
      File(p.join(tempDir.path, 'test_output001.mp4')).writeAsStringSync('');
      File(p.join(tempDir.path, 'test_output010.mp4')).writeAsStringSync('');
      File(p.join(tempDir.path, 'test_output002.mp4')).writeAsStringSync('');
      File(p.join(tempDir.path, 'test_output_notes.mp4')).writeAsStringSync('');
      File(p.join(tempDir.path, 'other_output001.mp4')).writeAsStringSync('');

      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(exitCode: 0);
      });

      final segments = await splitVideo(mockVideo.path, 'mp4', 0);
      final fileNames =
          segments.map((file) => file.uri.pathSegments.last).toList();

      expect(
        fileNames,
        containsAll(<String>[
          'test_output001.mp4',
          'test_output002.mp4',
          'test_output010.mp4',
        ]),
      );
      expect(fileNames, isNot(contains('test_output_notes.mp4')));
      expect(fileNames, isNot(contains('other_output001.mp4')));
      expect(fileNames, orderedEquals([...fileNames]..sort()));
    });

    test('Uses hyphenated segment names for repeated renders', () async {
      late List<String> capturedArguments;
      final repeatedVideo = File(p.join(tempDir.path, 'final-5.mp4'))
        ..createSync();
      File(p.join(tempDir.path, 'final-5-001.mp4')).writeAsStringSync('');
      File(p.join(tempDir.path, 'final-5-002.mp4')).writeAsStringSync('');
      File(p.join(tempDir.path, 'final-55001.mp4')).writeAsStringSync('');

      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        capturedArguments = arguments;
        return FakeProcess(exitCode: 0);
      });

      final segments = await splitVideo(repeatedVideo.path, 'mp4', 5);
      final fileNames =
          segments.map((file) => file.uri.pathSegments.last).toList();

      expect(fileNames, orderedEquals(['final-5-001.mp4', 'final-5-002.mp4']));
      expect(fileNames, isNot(contains('final-55001.mp4')));
      expect(capturedArguments.last, p.join(tempDir.path, 'final-5-%03d.mp4'));
    });
  });
}
