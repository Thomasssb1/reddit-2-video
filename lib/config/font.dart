import 'dart:io';
import 'package:reddit_2_video/config/config_item.dart';

class Font extends ConfigItem {
  final num size;
  final String _fontName;

  Font({
    required super.path,
    this.size = 18,
  }) : _fontName = _getFontName(path);

  Font.verdana()
      : size = 18,
        _fontName = 'verdana',
        super(path: 'defaults/fonts/verdana.ttf');

  static String _getFontName(String path) {
    try {
      return File(path).uri.pathSegments.last.split(".").first;
    } on StateError {
      return "Unknown";
    }
  }

  @override
  String toString() {
    return '$_fontName,$size';
  }

  String get name => _fontName;
}
