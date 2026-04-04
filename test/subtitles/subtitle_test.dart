import 'dart:convert';
import 'dart:io';

import 'package:reddit_2_video/subtitles/subtitle.dart';
import 'package:reddit_2_video/subtitles/subtitle_config.dart';
import 'package:reddit_2_video/subtitles/subtitle_line_data.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:test/test.dart';

void main() {
  late SubstationAlphaSubtitleColor color;

  setUp(() {
    color = SubstationAlphaSubtitleColor('#FFFFFF');
    Subtitle.setDurationReaderForTest(
        (file) => const Duration(milliseconds: 1500));
  });

  tearDown(() {
    Subtitle.resetForTest();
  });

  group('Subtitle', () {
    group('Subtitle.none', () {
      test('creates empty subtitle with no text', () {
        final subtitle = Subtitle.none();
        expect(subtitle.text, isEmpty);
      });

      test('creates subtitle with an empty config', () {
        final subtitle = Subtitle.none();
        expect(subtitle.config.segments, isEmpty);
      });
    });

    group('updateTitleColours', () {
      test('sets colour to supplied titleColour', () {
        final subtitle = Subtitle(
          text: 'Hello',
          color: color,
          config: SubtitleConfig.none(),
        );

        final titleColor = SubstationAlphaSubtitleColor('#FF0000');
        subtitle.updateTitleColours(titleColor);

        expect(subtitle.color.toString(), titleColor.toString());
      });

      test('sets highlightColour to white after updateTitleColours', () {
        final subtitle = Subtitle(
          text: 'Hello',
          color: color,
          config: SubtitleConfig.none(),
        );

        subtitle.updateTitleColours(SubstationAlphaSubtitleColor('#FF0000'));
        expect(
          subtitle.highlightColour.toString(),
          SubstationAlphaSubtitleColor('#FFFFFF').toString(),
        );
      });
    });

    group('addHighlight / removeHighlight', () {
      test('addHighlight prepends exact highlight colour tag to line text', () {
        final subtitle = Subtitle(
          text: 'hello world',
          color: color,
          config: SubtitleConfig.none(),
        );
        final line = SubtitleLineData(
          text: 'word',
          end: Duration(seconds: 1),
          start: Duration.zero,
          finalWord: false,
          segmentID: 1,
        );

        subtitle.addHighlight(line);

        expect(line.text, '{\\c&${subtitle.highlightColour}}word');
      });

      test('removeHighlight strips the colour tag, leaving original text', () {
        final subtitle = Subtitle(
          text: 'hello world',
          color: color,
          config: SubtitleConfig.none(),
        );
        final line = SubtitleLineData(
          text: 'word',
          end: Duration(seconds: 1),
          start: Duration.zero,
          finalWord: false,
          segmentID: 1,
        );
        subtitle.addHighlight(line);
        expect(line.text, '{\\c&${subtitle.highlightColour}}word');
        subtitle.removeHighlight(line);
        expect(line.text, 'word');
      });
    });

    group('generate', () {
      test('writes karaoke dialogue lines with subtitle timing', () async {
        final tempDir = Directory.systemTemp.createTempSync('subtitle_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final tts = File('${tempDir.path}/tts.mp3')..writeAsStringSync('');
        final configFile = File('${tempDir.path}/tts.words.json')
          ..writeAsStringSync(jsonEncode({
            'segments': [
              {
                'id': 1,
                'words': [
                  {'text': 'hello', 'start': 0.0, 'end': 0.5},
                  {'text': 'world', 'start': 0.5, 'end': 1.0},
                ]
              }
            ]
          }));
        final ass = File('${tempDir.path}/out.ass')..writeAsStringSync('');

        final subtitle = Subtitle(
          text: 'hello world',
          color: color,
          config: SubtitleConfig.fromFile(tts: tts, configFile: configFile),
        );

        await subtitle.generate(ass, const Duration(seconds: 1));

        final lines = ass.readAsLinesSync().where((e) => e.isNotEmpty).toList();
        expect(lines, hasLength(2));
        expect(lines.first, contains('Dialogue: 0,0:00:01.00,0:00:01.50'));
        expect(lines.first, contains('hello'));
        expect(lines.last, contains('0:00:02.50'));
      });
    });
  });

  group('SubtitleConfig', () {
    test('parses valid json segments', () {
      final tempDir = Directory.systemTemp.createTempSync('subtitle_config_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final tts = File('${tempDir.path}/tts.mp3')..writeAsStringSync('');
      final configFile = File('${tempDir.path}/tts.words.json')
        ..writeAsStringSync(jsonEncode({
          'segments': [
            {'id': 1, 'words': []}
          ]
        }));

      final config = SubtitleConfig.fromFile(tts: tts, configFile: configFile);

      expect(config.segments, hasLength(1));
    });

    test('throws for invalid json', () {
      final tempDir = Directory.systemTemp.createTempSync('subtitle_config_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final tts = File('${tempDir.path}/tts.mp3')..writeAsStringSync('');
      final configFile = File('${tempDir.path}/tts.words.json')
        ..writeAsStringSync('{not json}');

      expect(
        () => SubtitleConfig.fromFile(tts: tts, configFile: configFile),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SubtitleLineData', () {
    test('tracks final segment and final word state', () {
      final line = SubtitleLineData(
        text: 'word',
        end: const Duration(seconds: 1),
        start: Duration.zero,
        finalWord: true,
        segmentID: 2,
      );

      expect(line.isFinalWord, isTrue);
      expect(line.isFinalSegment(2), isTrue);
      expect(line.isFinalSegment(3), isFalse);
      expect(line.toString(), 'word');
    });
  });
}
