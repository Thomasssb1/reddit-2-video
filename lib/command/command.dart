import 'package:args/args.dart';
import 'package:reddit_2_video/exceptions/argument_missing_exception.dart';
import 'package:reddit_2_video/utils/logger.dart';

abstract class Command {
  final ArgParser? parser;

  void printHelp({
    String defaultsColourCode = ansiYellow,
    String optionsColourCode = ansiMagenta,
    String flagsColourCode = ansiGreen,
  }) {
    if (parser == null) {
      throw ArgumentMissingException(
          "No parser was provided. Unable to print help message.");
    }

    var usage = parser!.usage;

    var bracketsRegex = RegExp(r'\((defaults.+)\)');
    var sqBracketsRegex = RegExp(r'\[(.*?)\]');
    var dashRegex = RegExp(r'(?!-level|-colour|-domain)(\-\S+)');

    for (final match in bracketsRegex.allMatches(usage)) {
      usage = usage.replaceAll(
          match[0]!, '$defaultsColourCode${match[0]}$ansiReset');
    }
    for (final match in sqBracketsRegex.allMatches(usage)) {
      if (match[0] != '[no-]') {
        usage = usage.replaceAll(
            match[0]!, '$optionsColourCode${match[0]}$ansiReset');
      }
    }
    for (final match in dashRegex.allMatches(usage)) {
      usage =
          usage.replaceAll(match[0]!, '$flagsColourCode${match[0]}$ansiReset');
    }
    print(usage);
  }

  Command(this.parser);
}
