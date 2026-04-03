import 'package:reddit_2_video/config/config_item.dart';
import 'package:mp3_info/mp3_info.dart';

class EmptyNoise extends ConfigItem {
  int? position;
  EmptyNoise()
      : super(
          path: 'defaults/silence.mp3',
        );

  Duration get duration => MP3Processor.fromFile(path).duration;
}
