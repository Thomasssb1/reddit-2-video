import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';

class Alternate {
  final bool tts;
  final bool color;
  final SubstationAlphaSubtitleColor titleColour;

  const Alternate({
    required this.tts,
    required this.color,
    required this.titleColour,
  });

  @override
  String toString() =>
      "Alternate(tts: $tts, color: $color, titleColour: $titleColour)";
}
