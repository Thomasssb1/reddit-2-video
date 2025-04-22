import 'dart:io';
import 'package:test/test.dart';
import 'package:reddit_2_video/config/music.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks.dart';

void main() {
  late File mockfile;
  setUp(() {
    mockfile = MockFile();
  });

  test("Check music volume is within range", () {
    Music music = Music(
        path: "test.mp3",
        prePath: "/path/to/music",
        fileFactory: (_, __) => mockfile);
    expect(music.volume, greaterThanOrEqualTo(0.0));
    expect(music.volume, lessThanOrEqualTo(1.0));
  });
  test("Check music path is correct", () {
    Music music = Music(
        path: "test.mp3",
        prePath: "/path/to/music/",
        fileFactory: (_, __) => mockfile);
    when(() => mockfile.path).thenReturn("/path/to/music/test.mp3");
    expect(music.path.path, "/path/to/music/test.mp3");
  });
}
