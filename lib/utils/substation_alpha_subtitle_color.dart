import 'package:color/color.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';

/// Used to store the colour for each individual subtitle
/// The format that .ass uses is `HBBGGRR` so requires a bit of manipulation
/// to allow input from users who are used to the standard `#RRGGBB` format
class SubstationAlphaSubtitleColor {
  final Color _color;
  late String _red;
  late String _green;
  late String _blue;

  /// Converts a hex colour to a .ass compatible colour
  /// [hexColour] is in the format RRGGBB
  SubstationAlphaSubtitleColor(
    String value,
  ) : _color = Color.hex(SubstationAlphaSubtitleColor._convertToRRGGBB(value)) {
    RgbColor rgb = _color.toRgbColor();
    _red = _convertToHex(rgb.r);
    _green = _convertToHex(rgb.g);
    _blue = _convertToHex(rgb.b);
  }

  String _convertToHex(num val) => val.toInt().toRadixString(16);

  static String _convertToRRGGBB(String value) {
    try {
      String blue = value.substring(1, 3);
      String green = value.substring(3, 5);
      String red = value.substring(5, 7);
      return "$red$green$blue";
    } on RangeError {
      throw ArgumentMissingException(
          "Color $value is not valid. Colors need to be in the format #RRGGBB");
    }
  }

  @override
  String toString() => "\\1c&H$_blue$_green$_red";

  String toHash() => "#$_red$_green$_blue";
}
