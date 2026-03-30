import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    AppPaths.initForTest(Directory.current);
  });

  group("Test reading file", () {
    test("Check default lexicon file exists", () {
      File file = AppPaths.resolve('defaults/lexicons/lexemes.config.json');

      expect(file.existsSync(), true);
    });
    test("Check default lexicon file loads", () {
      final lexica = Lexica.fromConfig(
          configPath: "/defaults/lexicons/lexemes.config.json");

      expect(lexica.isNotEmpty, true);
    });

    test("Check lexicon file doesn't load with invalid path", () {
      expect(
          () => Lexica.fromConfig(
              configPath: "/defaults/lexicons/invalid.config.json"),
          throwsA(isA<FileSystemException>()));
    });
  });

  tearDown(() async {
    File tempFile = File("/defaults/lexicons/temp.config.json");
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
  });
}
