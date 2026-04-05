import 'dart:io';
import 'dart:convert';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../mocks.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lexica_test_');
    AppPaths.initForTest(tempDir);
    Directory('${tempDir.path}/defaults/lexicons').createSync(recursive: true);
  });

  tearDown(() async {
    Subprocess.resetForTest();
    tempDir.deleteSync(recursive: true);
  });

  File _writeLexicon(String name, {String xml = ''}) {
    final file = File('${tempDir.path}/defaults/lexicons/$name');
    file.writeAsStringSync(xml.isEmpty
        ? '<lexicon version="1.0" xml:lang="en-US"><lexeme><grapheme>a</grapheme><alias>b</alias></lexeme></lexicon>'
        : xml);
    return file;
  }

  File _writeConfig(String body) {
    final file = File('${tempDir.path}/defaults/lexicons/lexemes.config.json');
    file.writeAsStringSync(body);
    return file;
  }

  group("Test reading file", () {
    test("Check default lexicon file exists", () {
      final file = _writeConfig('{"lexemes": []}');

      expect(file.existsSync(), true);
    });

    test("Check default lexicon file loads", () {
      _writeLexicon('one.xml');
      _writeConfig(
          '{"lexemes": [{"id": "one", "file": "one.xml"}], "_last_updated": null}');

      final lexica = Lexica.fromConfig(
          configPath: 'defaults/lexicons/lexemes.config.json');

      expect(lexica.isNotEmpty, true);
    });

    test("Check lexicon file doesn't load with invalid path", () {
      expect(
          () => Lexica.fromConfig(
              configPath: 'defaults/lexicons/invalid.config.json'),
          throwsA(isA<FileSystemException>()));
    });

    test('throws for invalid xml format', () {
      _writeLexicon('broken.xml',
          xml: '<lexicon><lexeme><grapheme>x</grapheme>');
      _writeConfig(
          '{"lexemes": [{"id": "broken", "file": "broken.xml"}], "_last_updated": null}');

      expect(
        () => Lexica.fromConfig(
          configPath: 'defaults/lexicons/lexemes.config.json',
        ),
        throwsA(anyOf(isA<XmlParserException>(), isA<XmlTagException>())),
      );
    });

    test('limits the number of lexicons to five', () {
      for (var i = 0; i < 6; i++) {
        _writeLexicon('lex-$i.xml');
      }
      _writeConfig(
        jsonEncode({
          'lexemes': List.generate(
            6,
            (i) => {'id': 'lex-$i', 'file': 'lex-$i.xml'},
          ),
          '_last_updated': null,
        }),
      );

      final lexica = Lexica.fromConfig(
        configPath: 'defaults/lexicons/lexemes.config.json',
      );

      expect(lexica, hasLength(5));
      expect(
        lexica.map((e) => e.id),
        orderedEquals(['lex-0', 'lex-1', 'lex-2', 'lex-3', 'lex-4']),
      );
    });

    test('throws for invalid lexemes.config.json', () {
      _writeConfig('{"lexemes": "wrong"}');

      expect(
        () => Lexica.fromConfig(
          configPath: 'defaults/lexicons/lexemes.config.json',
        ),
        throwsA(isA<InvalidFileFormatException>()),
      );
    });

    test('throws when configured lexicon file does not exist', () {
      _writeConfig(
          '{"lexemes": [{"id": "missing", "file": "missing.xml"}], "_last_updated": null}');

      expect(
        () => Lexica.fromConfig(
          configPath: 'defaults/lexicons/lexemes.config.json',
        ),
        throwsA(isA<InvalidFileFormatException>()),
      );
    });
  });

  group('upload', () {
    test('succeeds when aws polly returns exit code 0', () async {
      final file = _writeLexicon('upload.xml');
      final lexica = Lexica.fromXML(file: file, id: 'upload');

      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        expect(executable, 'aws');
        expect(
          arguments,
          containsAll(['polly', 'put-lexicon', '--name', 'upload']),
        );
        return FakeProcess(exitCode: 0);
      });

      await lexica.upload();
    });

    test('throws when aws polly upload fails', () async {
      final file = _writeLexicon('upload.xml');
      final lexica = Lexica.fromXML(file: file, id: 'upload');

      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(exitCode: 1, err: 'bad lexicon');
      });

      await expectLater(
        () => lexica.upload(),
        throwsA(isA<PollyInvalidPlsLexicon>()),
      );
    });
  });

  group('equality', () {
    test('Lexicon compares grapheme and alias', () {
      expect(
        const Lexicon(grapheme: 'a', alias: 'b'),
        const Lexicon(grapheme: 'a', alias: 'b'),
      );
    });

    test('Lexica compares by parsed values', () {
      final fileOne = _writeLexicon('one.xml');
      final fileTwo = _writeLexicon('two.xml');

      final first = Lexica.fromXML(file: fileOne, id: 'one');
      final second = Lexica.fromXML(file: fileTwo, id: 'two');

      expect(first, second);
    });
  });
}
