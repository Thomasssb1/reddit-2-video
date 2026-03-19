class Prettify {
  static const String reset = '\x1b[0m';
  static const String red = '\x1b[31m';
  static const String green = '\x1b[32m';
  static const String yellow = '\x1b[33m';
  static const String magenta = '\x1b[35m';
  static const String underline = '\x1b[4m';

  static String colorText(String text, String colorCode) {
    return '$colorCode$text$reset';
  }
}

void printError(String message) {
  print(Prettify.colorText(message, Prettify.red));
}

void printWarning(String message) {
  print(Prettify.colorText(message, Prettify.yellow));
}

void printSuccess(String message) {
  print(Prettify.colorText(message, Prettify.green));
}

void printUnderline(String message) {
  print(Prettify.colorText(message, Prettify.underline))
}
