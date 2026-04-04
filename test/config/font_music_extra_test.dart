import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/font.dart';
import 'package:reddit_2_video/config/music.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('font_music_test_');
    AppPaths.initForTest(tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('Font', () {
    test('constructor derives font name from file path', () {
      final file = File('${tempDir.path}/defaults/fonts/custom.ttf')
        ..createSync(recursive: true);

      final font = Font(path: 'defaults/fonts/custom.ttf', size: 22);

      expect(font.name, 'custom');
      expect(font.toString(), 'custom,22');
      expect(font.path.path, file.path);
    });
  });

  group('Music', () {
    test('constructor parses valid volume', () {
      final file = File('${tempDir.path}/defaults/music.mp3')
        ..createSync(recursive: true);

      final music = Music(path: 'defaults/music.mp3', volume: 0.25);

      expect(music.path.path, file.path);
      expect(music.volume, 0.25);
    });

    test('constructor defaults to 1.0 when volume is omitted', () {
      File('${tempDir.path}/defaults/music.mp3').createSync(recursive: true);

      final music = Music(path: 'defaults/music.mp3');

      expect(music.volume, 1.0);
    });
  });
}
