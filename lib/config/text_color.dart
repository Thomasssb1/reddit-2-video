import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';

class TextColor {
  static const List<String> colors = [
    "#FFFFFF",
    "#DCF5F5",
    "#FF0000",
    "#8B0000",
    "#8B8B00",
    "#A9A9A9",
    "#006400",
    "#6BB7BD",
    "#8B008B",
    "#2F6B55",
    "#008CFF",
    "#CC3299",
    "#7A96E9",
    "#D30094",
    "#FF00FF",
    "#00D7FF",
    "#008000",
    "#82004B",
    "#8CE6F0",
    "#E6D8AD",
    "#FFFFE0",
    "#90EE90",
    "#D3D3D3",
    "#C1B6FF",
    "#E0FFFF",
    "#00FF00",
    "#FF00FF",
    "#800000",
    "#008080",
    "#00A5FF",
    "#CBC0FF",
    "#800080",
    "#800080",
    "#C0C0C0",
    "#00FFFF"
  ];

  static int _currentColour = 0;

  static SubstationAlphaSubtitleColor get current =>
      SubstationAlphaSubtitleColor(colors[_currentColour]);

  static void next() => _currentColour = ++_currentColour % colors.length;

  static void reset() => _currentColour = 0;
}
