import 'dart:async';
import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  Future<void> _createVideo(
      {required String path, required int seconds}) async {
    final result = await Process.run('ffmpeg', [
      '-f',
      'lavfi',
      '-i',
      'color=c=black:s=128x128:d=$seconds',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-y',
      path,
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to create test video: ${result.stderr}');
    }
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('endcard_test_');
    AppPaths.initForTest(tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test("Check end card file path is correct", () async {
    File testFile = File('${tempDir.path}/endcard.gif');
    testFile.createSync();

    EndCard result = await EndCard.create(
      path: "endcard.gif",
    );

    expect(result.path.path, testFile.path);
  });

  test("Check end card uses override duration for image", () async {
    File testFile = File('${tempDir.path}/image.png');
    testFile.createSync();

    EndCard result = await EndCard.create(
      path: "image.png",
      durationOverride: Duration(seconds: 8),
    );

    expect(result.duration, Duration(seconds: 8));
  });

  test(
      "Check end card throws ArgumentMissingException for image with no override",
      () async {
    File testFile = File('${tempDir.path}/image.jpg');
    testFile.createSync();

    expect(() => EndCard.create(path: "image.jpg"),
        throwsA(isA<ArgumentMissingException>()));
  });

  test("Warns when overriding inferred duration for video and uses override",
      () async {
    final videoFile = File('${tempDir.path}/clip.mp4');
    await _createVideo(path: videoFile.path, seconds: 2);

    final printed = <String>[];
    late EndCard result;

    await runZoned(() async {
      result = await EndCard.create(
        path: "clip.mp4",
        durationOverride: Duration(seconds: 8),
      );
    }, zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        printed.add(line);
      },
    ));

    expect(result.duration, Duration(seconds: 8));
    expect(
      printed.any((line) => line.contains(
          '--end-card-length is overriding the inferred end-card duration')),
      isTrue,
    );
  });

  test("Infers duration from a video/gif file when no override is provided",
      () async {
    final videoFile = File('${tempDir.path}/clip.mp4');
    await _createVideo(path: videoFile.path, seconds: 2);

    final result = await EndCard.create(path: "clip.mp4");

    expect(result.duration, Duration(seconds: 2));
  });
}
