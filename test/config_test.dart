import 'dart:io';

import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/font.dart';
import 'package:test/test.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';

void main() {
  group('Config testing', () {
    group('Font class', () {
      test("Default font class", () {
        Font font = Font.verdana();
        expect(font.size, 18);
        expect(font.name, 'verdana');
      });
      test("Custom font class", () {
        Font font = Font(path: 'test/data/verdana.ttf', size: 24);
        expect(font.size, 24);
        expect(font.name, 'verdana');
      });
      test("Invalid font path", () {
        expect(Font(path: 'test/data/invalid'),
            throwsA(TypeMatcher<FileSystemException>()));
      });
    });
    group('BackgroundVideo class', () {
      // Need to figure out how to test downloading etc without actually downloading each time
      // probably use a short youtube video
    });
    group('Lexica class', () {
      test('Manual lexica creation', () {
        List<Lexicon> lexicons = [
          Lexicon(grapheme: 'test', alias: 'test-alias'),
          Lexicon(grapheme: 'test2', alias: 'test2-alis')
        ];
        Lexica lexica = Lexica(
            xmlVersion: 1.0,
            languageCode: 'en-US',
            lexicons: lexicons,
            path: "test/data/lexicons_gen.xml");
        expect(lexica.lexicons.length, 2);

        String xmlContent = lexica.createXMLFile();
        lexica.path.writeAsStringSync(xmlContent);

        Lexica fileLexica = Lexica.fromXML(path: "test/data/lexicons.xml");
        expect(lexica == fileLexica, true);
      });
    });
  });
}
