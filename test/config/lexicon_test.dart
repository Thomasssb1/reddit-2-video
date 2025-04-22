import 'dart:io';

import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import '../mocks.dart';

void main() {
  group("Test reading file", () {
    test("Check default lexicon file exists", () {
      File file = File(
          "${Directory.current.path}/defaults/lexicons/lexemes.config.json");

      expect(file.existsSync(), true);
    });
    test("Check default lexicon file loads", () {
      final lexica = Lexica.fromConfig(
          configPath: "/defaults/lexicons/lexemes.config.json",
          prePath: Directory.current.path);

      expect(lexica.isNotEmpty, true);
    });

    test("Check lexicon file doesn't load with invalid path", () {
      expect(
          () => Lexica.fromConfig(
              configPath: "/defaults/lexicons/invalid.config.json",
              prePath: Directory.current.path),
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
