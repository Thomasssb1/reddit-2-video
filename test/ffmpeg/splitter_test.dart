import 'dart:io';
import 'package:test/test.dart';
import 'package:reddit_2_video/ffmpeg/splitter.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import '../test_helper.dart';

void main() {
  group('FFmpeg Splitter Tests', () {
    const String testVideoPath = 'test_output.mp4';
    late File mockVideo;

    setUp(() async {
      await createDummyVideo(testVideoPath);
      mockVideo = File(testVideoPath);
    });

    tearDown(() {
      if (mockVideo.existsSync()) {
        mockVideo.deleteSync();
      }

      // Attempt to clean up any split segments generated
      var dir = Directory('.');
      for (var entity in dir.listSync()) {
        if (entity.path.contains(RegExp(r'test_output\d+\.mp4$'))) {
          entity.deleteSync();
        }
      }
    });

    test('Throws FFmpegCommandException when splitting an invalid video',
        () async {
      // Overwrite with invalid content to force failure
      mockVideo.writeAsStringSync("not a video");

      expect(
        () async => await splitVideo(mockVideo.path, 'mp4', 0),
        throwsA(isA<FFmpegCommandException>()
            .having((e) => e.command, 'command', isNotEmpty)),
      );
    });

    test('Successfully splits a valid video (Happy Path)', () async {
      // Since our dummy is 1s and segment_time is 55s, it will produce 1 segment
      final segments = await splitVideo(mockVideo.path, 'mp4', 0);

      expect(segments, isNotEmpty);
      expect(segments.first.existsSync(), isTrue);
      expect(segments.first.path, contains('test_output'));
    });

    test('Returns only matching segments in a deterministic order', () async {
      File('test_output001.mp4').writeAsStringSync('');
      File('test_output010.mp4').writeAsStringSync('');
      File('test_output002.mp4').writeAsStringSync('');
      File('test_output_notes.mp4').writeAsStringSync('');
      File('other_output001.mp4').writeAsStringSync('');

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
