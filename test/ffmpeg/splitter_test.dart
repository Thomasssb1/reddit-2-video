import 'dart:io';

import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/ffmpeg/splitter.dart';
import 'package:reddit_2_video/utils/subprocess.dart';
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
        return FakeProcess(exitCode: 1);
      });

      await expectLater(
        () => splitVideo(mockVideo.path, 'mp4', 0),
        throwsA(isA<FFmpegCommandException>()
            .having((e) => e.command, 'command', isNotEmpty)),
      );
    });

    test('Successfully returns generated matching segments', () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        File('${tempDir.path}/test_output000.mp4').writeAsStringSync('');
        return FakeProcess(exitCode: 0);
      });

      final segments = await splitVideo(mockVideo.path, 'mp4', 0);

      expect(segments, isNotEmpty);
      expect(segments.first.existsSync(), isTrue);
      expect(segments.first.path, contains('test_output'));
    });

    test('Returns only matching segments in a deterministic order', () async {
      File('${tempDir.path}/test_output001.mp4').writeAsStringSync('');
      File('${tempDir.path}/test_output010.mp4').writeAsStringSync('');
      File('${tempDir.path}/test_output002.mp4').writeAsStringSync('');
      File('${tempDir.path}/test_output_notes.mp4').writeAsStringSync('');
      File('${tempDir.path}/other_output001.mp4').writeAsStringSync('');

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
  });
}
