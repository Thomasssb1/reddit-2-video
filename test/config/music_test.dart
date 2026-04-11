import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/music.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('music_test_');
    AppPaths.initForTest(tempDir);
    // Create a dummy music file
    File('${tempDir.path}/test.mp3').createSync();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test("Check music volume is within range", () {
    Music music = Music(path: "test.mp3");
    expect(music.volume, greaterThanOrEqualTo(0.0));
    expect(music.volume, lessThanOrEqualTo(1.0));
  });

  test("Check music path is correct", () {
    Music music = Music(path: "test.mp3");
    expect(
      p.normalize(music.path.path),
      p.normalize(p.join(tempDir.path, 'test.mp3')),
    );
  });
}
