import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:test/test.dart';
import 'package:reddit_2_video/config/text_color.dart';

void main() {
  setUp(() {
    TextColor.reset();
  });
  group("TextColor checks", () {
    test("Check default text color is black", () {
      SubstationAlphaSubtitleColor defaultColor =
          SubstationAlphaSubtitleColor("#FFFFFF");
      expect(TextColor.current, defaultColor);
    });
    test("Check cycling to next colour works", () {
      TextColor.next();
      SubstationAlphaSubtitleColor nextColor =
          SubstationAlphaSubtitleColor("#DCF5F5");
      expect(TextColor.current, nextColor);
    });
    test("Check resetting colour works", () {
      TextColor.next();
      TextColor.reset();
      SubstationAlphaSubtitleColor resetColor =
          SubstationAlphaSubtitleColor("#FFFFFF");
      expect(TextColor.current, resetColor);
    });
  });
  group("SubstationAlphaSubtitleColor checks", () {
    group("Check conversion works as expected", () {
      test("Check conversion from full red", () {
        SubstationAlphaSubtitleColor color =
            SubstationAlphaSubtitleColor("#FF0000");
        expect(color.toString(), "\\1c&H0000FF");
      });
      test("Check conversion from full blue", () {
        SubstationAlphaSubtitleColor color =
            SubstationAlphaSubtitleColor("#0000FF");
        expect(color.toString(), "\\1c&HFF0000");
      });
      test("Check conversion from full green", () {
        SubstationAlphaSubtitleColor color =
            SubstationAlphaSubtitleColor("#00FF00");
        expect(color.toString(), "\\1c&H00FF00");
      });
      test("Check conversion from full white", () {
        SubstationAlphaSubtitleColor color =
            SubstationAlphaSubtitleColor("#FFFFFF");
        expect(color.toString(), "\\1c&HFFFFFF");
      });
      test("Check conversion works with leading #", () {
        SubstationAlphaSubtitleColor color =
            SubstationAlphaSubtitleColor("#FF00FF");
        expect(color.toString(), "\\1c&HFF00FF");
      });
      test("Check conversion works with leading H", () {
        SubstationAlphaSubtitleColor color =
            SubstationAlphaSubtitleColor("HFF00FF");
        expect(color.toString(), "\\1c&HFF00FF");
      });

      test("Check equality works for matching colours", () {
        expect(
          SubstationAlphaSubtitleColor("#FF00FF"),
          SubstationAlphaSubtitleColor("HFF00FF"),
        );
      });

      test("Check toHash and hashCode are stable", () {
        final color = SubstationAlphaSubtitleColor("#00FF00");
        expect(color.toHash(), "#00FF00");
        expect(
            color.hashCode, SubstationAlphaSubtitleColor("#00FF00").hashCode);
      });
    });
  });
}
