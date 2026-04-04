import 'package:reddit_2_video/config/config_item.dart';

class Music extends ConfigItem {
  final double volume;
  int? position;

  Music({
    required String path,
    this.volume = 1.0,
  }) : super(path: path);
}
