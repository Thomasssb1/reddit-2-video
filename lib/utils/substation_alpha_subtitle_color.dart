import 'package:color/color.dart';
import 'package:path/path.dart';

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
  ) : _color = Color.hex(value.replaceFirst("#", "").replaceFirst("H", "")) {
    RgbColor rgb = _color.toRgbColor();
    _red = _convertToHex(rgb.r).padLeft(2, '0').toUpperCase();
    _green = _convertToHex(rgb.g).padLeft(2, '0').toUpperCase();
    _blue = _convertToHex(rgb.b).padLeft(2, '0').toUpperCase();
  }

  String _convertToHex(num val) => val.toInt().toRadixString(16);

  @override
  String toString() => "\\1c&H$_blue$_green$_red";

  @override
  bool operator ==(Object other) {
    return other is SubstationAlphaSubtitleColor && other.toHash() == toHash();
  }

  @override
  int get hashCode => hash(toHash());

  String toHash() => "#$_red$_green$_blue";
}
