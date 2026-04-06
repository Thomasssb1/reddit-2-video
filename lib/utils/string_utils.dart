import 'package:remove_emoji/remove_emoji.dart';

extension StringUtils on String {
  bool parseBool() {
    return this == 'on';
  }

  String cleanse() {
    return RemoveEmoji().clean(this).replaceAll('&amp;#x200B;', '');
  }
}
