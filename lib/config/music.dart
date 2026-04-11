import 'package:reddit_2_video/config/config_item.dart';

class Music extends ConfigItem {
  final double volume;
  int? position;

  Music({
    required super.path,
    this.volume = 1.0,
  });
}
