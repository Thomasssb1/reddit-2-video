import 'package:reddit_2_video/config/config_item.dart';

class EndCard extends ConfigItem {
  final Duration duration;
  int? position;

  EndCard({required String path})
      // TODO: allow for custom duration
      : duration = Duration(milliseconds: 2000),
        super(path: path);
}
