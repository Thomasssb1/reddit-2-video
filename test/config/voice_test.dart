import 'dart:io';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/exceptions/argument_conflict_exception.dart';
import 'package:reddit_2_video/exceptions/invalid_file_format_exception.dart';
import 'package:test/test.dart';
import 'package:reddit_2_video/config/voices/voice.dart';
import 'package:reddit_2_video/config/voices/voices.dart';

import 'package:mocktail/mocktail.dart';
import '../mocks.dart';

void main() {
  late ParsedCommand command;
  setUp(() {
    AppPaths.initForTest(Directory.current);
    command = MockParsedCommand();
  });
  group("Test Voices class", () {
    test("Check loading voices from voice.config.json with neural enabled", () {
      when(() => command.ntts).thenReturn(true);
      List<Voice> voices = Voices.fromFile(command);
      expect(voices.length, greaterThan(0));
      expect(voices.map((v) => v.neural).toList(), everyElement(isTrue));
    });
    test("Check loading voices from voice.config.json with neural disabled",
        () {
      when(() => command.ntts).thenReturn(false);
      List<Voice> voices = Voices.fromFile(command);
      expect(voices.length, greaterThan(0));
      expect(voices.map((v) => v.standard).toList(), everyElement(isTrue));
    });
    test("Check creating voice with conflicting speech engines", () {
      when(() => command.ntts).thenReturn(false);
      when(() => command.voice).thenReturn("Brian");
      Voice voice = Voice(id: "Brian", neural: true, standard: false);
      expect(
          () => Voices([voice], voice, command),
          throwsA(isA<ArgumentConflictException>().having(
              (e) => e.message,
              "message",
              contains(
                  "Unable to use a neural voice with standard tts engine"))));
    });
    test("Check creating voice with conflicting speech engines", () {
      when(() => command.ntts).thenReturn(true);
      when(() => command.voice).thenReturn("Brian");
      Voice voice = Voice(id: "Brian", neural: false, standard: true);
      expect(() => Voices([voice], voice, command),
          throwsA(isA<ArgumentConflictException>()));
    });
    test("Check matching voice", () {
      when(() => command.ntts).thenReturn(false);
      Voice voice = Voice(id: "Brian", neural: false, standard: true);
      Voices voices = Voices([voice], voice, command);
      expect(voices.called("Brian"), voice);
    });
    test("Check getting current voice", () {
      when(() => command.ntts).thenReturn(false);
      Voice voice = Voice(id: "Brian", neural: false, standard: true);
      Voices voices = Voices([voice], voice, command);
      expect(voices.current, voice);
    });
    test("Check getting current voice", () {
      when(() => command.ntts).thenReturn(true);
      List<Voice> voices = Voices.fromFile(command);
      Voices voice = Voices(voices, voices[0], command);
      expect(voice.current, voices[0]);
    });
    test("Check getting next voice", () {
      when(() => command.ntts).thenReturn(true);
      List<Voice> voices = Voices.fromFile(command);
      Voices voice = Voices(voices, voices[0], command);
      voice.next();
      expect(voice.current, voices[1]);
    });
    test("Check resetting voice", () {
      when(() => command.ntts).thenReturn(true);
      List<Voice> voices = Voices.fromFile(command);
      Voices voice = Voices(voices, voices[0], command);
      voice.next();
      voice.reset();
      expect(voice.current, voices[0]);
    });

    test('parses a custom voices file correctly', () {
      final tempDir = Directory.systemTemp.createTempSync('voices_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      AppPaths.initForTest(tempDir);
      final file = File('${tempDir.path}/defaults/voice.config.json');
      file.createSync(recursive: true);
      file.writeAsStringSync('''
{
  "voices": [
    {"name": "Amy", "neural": true, "standard": true},
    {"name": "Brian", "standard": true, "disabled": true},
    {"name": "Emma", "standard": true}
  ]
}
''');

      when(() => command.ntts).thenReturn(false);
      final voices = Voices.fromFile(command);

      expect(voices.map((e) => e.id), orderedEquals(['Amy', 'Emma']));
    });

    test('throws for invalid voices json format', () {
      final tempDir = Directory.systemTemp.createTempSync('voices_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      AppPaths.initForTest(tempDir);
      final file = File('${tempDir.path}/defaults/voice.config.json');
      file.createSync(recursive: true);
      file.writeAsStringSync('{"voices": "wrong"}');

      when(() => command.ntts).thenReturn(false);

      expect(() => Voices.fromFile(command),
          throwsA(isA<InvalidFileFormatException>()));
    });

    test('falls back to first voice when current voice does not exist', () {
      when(() => command.ntts).thenReturn(true);
      when(() => command.voice).thenReturn('Missing');

      final brian = Voice(id: 'Brian', neural: true, standard: true);
      final amy = Voice(id: 'Amy', neural: true, standard: true);

      final voices =
          Voices([brian, amy], Voice(id: 'Missing', neural: true), command);

      expect(voices.current, brian);
    });

    test('set changes current voice and falls back to standard when missing',
        () {
      when(() => command.ntts).thenReturn(true);
      when(() => command.voice).thenReturn('Brian');

      final brian = Voice(id: 'Brian', neural: true, standard: true);
      final amy = Voice(id: 'Amy', neural: true, standard: true);
      final voices = Voices([brian, amy], brian, command);

      voices.set(amy);
      expect(voices.current, amy);

      voices.set(Voice(id: 'Missing', neural: true, standard: true));
      expect(voices.current, brian);
    });
  });
  group("Test Voice class", () {
    test("Check creating voice", () {
      Voice voice = Voice(id: "Brian", neural: true, standard: true);
      expect(voice.id, "Brian");
      expect(voice.neural, true);
      expect(voice.standard, true);
      expect(voice.newscaster, false);
    });
    test("Check creating voice with newscaster", () {
      Voice voice =
          Voice(id: "Brian", neural: true, standard: true, newscaster: true);
      expect(voice.id, "Brian");
      expect(voice.neural, true);
      expect(voice.standard, true);
      expect(voice.newscaster, true);
    });
    test("Check creating voice with disabled", () {
      Voice voice =
          Voice(id: "Brian", neural: true, standard: true, disabled: true);
      expect(voice.id, "Brian");
      expect(voice.neural, true);
      expect(voice.standard, true);
      expect(voice.newscaster, false);
      expect(voice.disabled, true);
    });
    test("Check standard voice is correct", () {
      Voice voice = Voice.standard();
      expect(voice.id, "Brian");
      expect(voice.neural, true);
      expect(voice.standard, true);
      expect(voice.newscaster, false);
    });
    test("Check voice type is aws polly", () {
      Voice voice = Voice.standard();
      expect(voice.isAWSPolly, true);
    });

    test('checks equality by id', () {
      expect(
        Voice(id: 'Brian', neural: true, standard: true),
        Voice(id: 'Brian', neural: false, standard: false),
      );
    });
  });
}
