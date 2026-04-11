import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    AppPaths.initForTest(Directory.current);
  });

  tearDown(() {
    EmptyNoise.resetForTest();
  });

  test("Check empty noise file exists", () {
    EmptyNoise emptyNoise = EmptyNoise();
    expect(emptyNoise.path.existsSync(), true);
  });

  test("Check length of empty noise file", () {
    EmptyNoise emptyNoise = EmptyNoise();
    Duration tolerance = Duration(milliseconds: 100);
    Duration expectedDuration = Duration(milliseconds: 1000);

    Duration calculatedDuration =
        (emptyNoise.duration - expectedDuration).abs();

    expect(calculatedDuration <= tolerance, true);
  });

  test("Check mocked length of empty noise file", () {
    EmptyNoise.setDurationReaderForTest((file) => Duration(seconds: 2));

    EmptyNoise emptyNoise = EmptyNoise();

    expect(emptyNoise.duration, Duration(seconds: 2));
  });
}
