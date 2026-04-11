import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
import 'package:test/test.dart';
import '../mocks.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('endcard_test_');
    AppPaths.initForTest(tempDir);
  });

  tearDown(() {
    Subprocess.resetForTest();
    tempDir.deleteSync(recursive: true);
  });

  test("Check end card file path is correct", () async {
    File testFile = File('${tempDir.path}/endcard.gif');
    testFile.createSync();

    EndCard result = await EndCard.create(
      path: "endcard.gif",
    );

    expect(p.normalize(result.path.path), p.normalize(testFile.path));
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
    videoFile.createSync();
    final stdoutBuffer = StringBuffer();
    logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

    Subprocess.setStartForTest((executable, arguments,
        {workingDirectory,
        environment,
        includeParentEnvironment = true,
        runInShell = false,
        mode = ProcessStartMode.normal}) async {
      return FakeProcess(
        exitCode: 0,
        out: '{"format":{"duration":"2.0"}}',
      );
    });

    final result = await EndCard.create(
      path: "clip.mp4",
      durationOverride: Duration(seconds: 8),
    );

    expect(result.duration, Duration(seconds: 8));
    expect(
      stdoutBuffer.toString(),
      contains(
          '--end-card-length is overriding the inferred end-card duration'),
    );
  });

  test("Infers duration from a video/gif file when no override is provided",
      () async {
    final videoFile = File('${tempDir.path}/clip.mp4');
    videoFile.createSync();

    Subprocess.setStartForTest((executable, arguments,
        {workingDirectory,
        environment,
        includeParentEnvironment = true,
        runInShell = false,
        mode = ProcessStartMode.normal}) async {
      return FakeProcess(
        exitCode: 0,
        out: '{"format":{"duration":"2.0"}}',
      );
    });

    final result = await EndCard.create(path: "clip.mp4");

    expect(result.duration, Duration(seconds: 2));
  });

  test("Falls back to 5 seconds when probe fails", () async {
    final videoFile = File('${tempDir.path}/clip.mp4');
    videoFile.createSync();

    Subprocess.setStartForTest((executable, arguments,
        {workingDirectory,
        environment,
        includeParentEnvironment = true,
        runInShell = false,
        mode = ProcessStartMode.normal}) async {
      return FakeProcess(exitCode: 1, err: 'ffprobe failed');
    });

    final result = await EndCard.create(path: "clip.mp4");

    expect(result.duration, const Duration(seconds: 5));
  });

  test("Falls back to 5 seconds when probe output is invalid", () async {
    final videoFile = File('${tempDir.path}/clip.mp4');
    videoFile.createSync();

    Subprocess.setStartForTest((executable, arguments,
        {workingDirectory,
        environment,
        includeParentEnvironment = true,
        runInShell = false,
        mode = ProcessStartMode.normal}) async {
      return FakeProcess(exitCode: 0, out: '{not json}');
    });

    final result = await EndCard.create(path: "clip.mp4");

    expect(result.duration, const Duration(seconds: 5));
  });
}
