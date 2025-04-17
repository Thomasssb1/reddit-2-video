import 'dart:io';

import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:test/test.dart';

void main() {
  test("Check empty noise file exists", () {
    EmptyNoise emptyNoise = EmptyNoise(prePath: Directory.current.path);
    expect(emptyNoise.path.existsSync(), true);
  });

  test("Check length of empty noise file", () {
    EmptyNoise emptyNoise = EmptyNoise(prePath: Directory.current.path);
    Duration tolerance = Duration(milliseconds: 100);
    Duration expectedDuration = Duration(milliseconds: 1000);

    Duration calculatedDuration =
        (emptyNoise.duration - expectedDuration).abs();

    expect(calculatedDuration <= tolerance, true);
  });
}
