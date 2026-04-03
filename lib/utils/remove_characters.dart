import 'package:remove_emoji/remove_emoji.dart';

class RemoveCharacters extends RemoveEmoji {
  String cleanse(String text) =>
      super.clean(text).replaceAll('&amp;#x200B;', '');
}
