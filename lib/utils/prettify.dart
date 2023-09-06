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

/// print the usage formatted with colours for particular uses
void printHelp(
  String usage,
) {
  var bracketsRegex = RegExp(r'\((defaults.+)\)');
  var sqBracketsRegex = RegExp(r'\[(.*?)\]');
  var dashRegex = RegExp(r'(?!-level|-colour|-domain)(\-\S+)');

  for (final match in bracketsRegex.allMatches(usage)) {
    usage = usage.replaceAll(match[0]!, '\x1b[33m${match[0]}\x1b[0m');
  }
  for (final match in sqBracketsRegex.allMatches(usage)) {
    if (match[0] != '[no-]') {
      usage = usage.replaceAll(match[0]!, '\x1b[35m${match[0]}\x1b[0m');
    }
  }
  for (final match in dashRegex.allMatches(usage)) {
    usage = usage.replaceAll(match[0]!, '\x1b[32m${match[0]}\x1b[0m');
  }
  print(usage);
}
