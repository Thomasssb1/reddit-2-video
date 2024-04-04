import 'package:reddit_2_video/config/config_item.dart';

class Font extends ConfigItem {
  final num size;
  final String _fontName;

  Font({
    super.path = 'defaults/fonts/verdana.ttf',
    this.size = 18,
  }) : _fontName = _getFontName(path);

  static String _getFontName(String path) {
    return path.split('/').last.split('.').first;
  }

  @override
  String toString() {
    return '$_fontName,$size';
  }
}
