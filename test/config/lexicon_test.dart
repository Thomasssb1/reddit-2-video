import 'dart:io';
import 'dart:convert';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
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

    test('throws InvalidFileFormatException when lexeme xml is missing alias',
        () {
      final file = _writeLexicon(
        'missing-alias.xml',
        xml:
            '<lexicon version="1.0" xml:lang="en-US"><lexeme><grapheme>x</grapheme></lexeme></lexicon>',
      );

      expect(
        () => Lexica.fromXML(file: file, id: 'missing-alias'),
        throwsA(isA<InvalidFileFormatException>()),
      );
    });

    test('throws InvalidFileFormatException when xml version cannot be parsed',
        () {
      final file = _writeLexicon(
        'bad-version.xml',
        xml:
            '<lexicon version="abc" xml:lang="en-US"><lexeme><grapheme>x</grapheme><alias>y</alias></lexeme></lexicon>',
      );

      expect(
        () => Lexica.fromXML(file: file, id: 'bad-version'),
        throwsA(isA<InvalidFileFormatException>()),
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

    test('throws InvalidFileFormatException for malformed config json', () {
      _writeConfig('{');

      expect(
        () => Lexica.fromConfig(
          configPath: 'defaults/lexicons/lexemes.config.json',
        ),
        throwsA(isA<InvalidFileFormatException>()),
      );
    });

    test('throws InvalidFileFormatException when lexemes field is missing', () {
      _writeConfig('{"_last_updated": null}');

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

  group('timestamps', () {
    test('setLastUpdatedForTest writes the provided timestamp', () async {
      final config = _writeConfig('{"lexemes": [], "_last_updated": null}');
      final expected = DateTime.utc(2024, 1, 2, 3, 4, 5);

      Lexica.setLastUpdatedForTest(expected, config.path);

      final json =
          jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
      expect(DateTime.parse(json['_last_updated'] as String), expected);
    });

    test('getLastUpdatedForTest returns the stored timestamp', () async {
      final expected = DateTime.utc(2024, 2, 3, 4, 5, 6);
      final config = _writeConfig(
        jsonEncode({
          'lexemes': [],
          '_last_updated': expected.toString(),
        }),
      );

      final actual = await Lexica.getLastUpdatedForTest(config.path);

      expect(actual, expected);
    });

    test('getLastUpdatedForTest throws InvalidFileFormatException for bad json',
        () async {
      final config = _writeConfig('{');

      await expectLater(
        () => Lexica.getLastUpdatedForTest(config.path),
        throwsA(isA<InvalidFileFormatException>()),
      );
    });

    test(
        'getLastUpdatedForTest resets invalid timestamp text to epoch and null',
        () async {
      final config = _writeConfig(
        jsonEncode({
          'lexemes': [],
          '_last_updated': 'not-a-date',
        }),
      );

      final actual = await Lexica.getLastUpdatedForTest(config.path);
      final json =
          jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;

      expect(actual, DateTime(1970, 1, 1));
      expect(json['_last_updated'], isNull);
    });

    test(
        'update uploads lexica and refreshes last updated when files are newer',
        () async {
      final oldTime = DateTime.utc(2024, 1, 1);
      final config = _writeConfig(
        jsonEncode({
          'lexemes': [],
          '_last_updated': oldTime.toString(),
        }),
      );
      final lexemeFile = _writeLexicon('newer.xml');
      final newerTime = oldTime.add(const Duration(days: 1));
      lexemeFile.setLastModifiedSync(newerTime);

      final lexica = MockLexica();
      when(() => lexica.upload(verbose: any(named: 'verbose')))
          .thenAnswer((_) async {});

      await Lexica.update(config.path, [lexica]);

      verify(() => lexica.upload(verbose: false)).called(1);
      final updated = await Lexica.getLastUpdatedForTest(config.path);
      expect(updated.isAfter(oldTime), isTrue);
    });
  });

  group('createXMLFile', () {
    test('writes xml content to the configured file', () {
      final outputFile = File(
        p.join(tempDir.path, 'defaults', 'lexicons', 'created.xml'),
      )..createSync();
      final lexica = Lexica(
        xmlVersion: 1.0,
        languageCode: 'en-US',
        id: 'created',
        lexicons: const [Lexicon(grapheme: 'a', alias: 'b')],
        path: outputFile.path,
      );

      final xml = lexica.createXMLFile();

      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync(), xml);
      expect(xml, contains('<grapheme>a</grapheme>'));
      expect(xml, contains('<alias>b</alias>'));
    });

    test('overwrites an existing xml file', () {
      final outputFile = File(
        p.join(tempDir.path, 'defaults', 'lexicons', 'overwrite.xml'),
      )..writeAsStringSync('old-content');
      final lexica = Lexica(
        xmlVersion: 1.0,
        languageCode: 'en-US',
        id: 'overwrite',
        lexicons: const [Lexicon(grapheme: 'new', alias: 'value')],
        path: outputFile.path,
      );

      final xml = lexica.createXMLFile();

      expect(outputFile.readAsStringSync(), xml);
      expect(outputFile.readAsStringSync(), isNot('old-content'));
      expect(
          outputFile.readAsStringSync(), contains('<grapheme>new</grapheme>'));
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

    test('Lexica toString returns id', () {
      final file = _writeLexicon('string.xml');
      final lexica = Lexica.fromXML(file: file, id: 'string-id');

      expect(lexica.toString(), 'string-id');
    });
  });
}
