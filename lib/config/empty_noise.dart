import 'package:reddit_2_video/config/config_item.dart';

class EmptyNoise extends ConfigItem {
  int? position;
  EmptyNoise({required super.prePath})
      : super(
          path: "defaults/silence.wav",
        );
}
