import 'package:args/args.dart';

/// print with red text
void printError(
  String message,
) {
  print("\x1b[31m$message\x1b[0m");
}

/// print with orange text
void printWarning(
  String message,
) {
  print("\x1b[33m$message\x1b[0m");
}

/// print with green text
void printSuccess(
  String message,
) {
  print("\x1b[32m$message\x1b[0m");
}

/// print with underlined text
void printUnderline(
  String message,
) {
  print("\x1b[4m$message\x1b[0m");
}

/// print the usage formatted with colours
extension PrintHelp on ArgParser {
  void printHelp({
    String defaultsColourCode = "\x1b[33m",
    String optionsColourCode = "\x1b[35m",
    String flagsColourCode = "\x1b[32m",
  }) {
    String usage = this.usage;

    var bracketsRegex = RegExp(r'\((defaults.+)\)');
    var sqBracketsRegex = RegExp(r'\[(.*?)\]');
    var dashRegex = RegExp(r'(?!-level|-colour|-domain)(\-\S+)');

    for (final match in bracketsRegex.allMatches(usage)) {
      usage =
          usage.replaceAll(match[0]!, '$defaultsColourCode${match[0]}\x1b[0m');
    }
    for (final match in sqBracketsRegex.allMatches(usage)) {
      if (match[0] != '[no-]') {
        usage =
            usage.replaceAll(match[0]!, '$optionsColourCode${match[0]}\x1b[0m');
      }
    }
    for (final match in dashRegex.allMatches(usage)) {
      usage = usage.replaceAll(match[0]!, '$flagsColourCode${match[0]}\x1b[0m');
    }
    print(usage);
  }
}
