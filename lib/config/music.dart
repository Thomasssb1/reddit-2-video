import 'package:reddit_2_video/config/config_item.dart';
import 'package:reddit_2_video/exceptions/warning.dart';

class Music extends ConfigItem {
  double volume = 1.0;
  int? position;

  Music({
    required String path,
    required super.prePath,
    String? volume = "1.0",
  }) : super(path: path) {
    try {
      this.volume = double.parse(volume ?? "1.0");
    } on FormatException {
      Warning.warn("Volume must be a double. Defaulting to 1.0");
      this.volume = 1.0;
    }
  }
}
