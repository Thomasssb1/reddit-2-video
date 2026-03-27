import 'package:reddit_2_video/subtitles/subtitle.dart';
import 'package:reddit_2_video/subtitles/subtitle_config.dart';
import 'package:reddit_2_video/subtitles/subtitle_line_data.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:test/test.dart';

void main() {
  late SubstationAlphaSubtitleColor color;

  setUp(() {
    color = SubstationAlphaSubtitleColor('#FFFFFF');
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
      test('addHighlight wraps subtitle line text with colour tag', () {
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
        expect(line.text, contains(r'{\c&'));
        expect(line.text, contains('word'));
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
        subtitle.removeHighlight(line);
        expect(line.text, 'word');
      });
    });
  });
}
