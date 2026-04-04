import 'package:args/args.dart';
import 'package:reddit_2_video/exceptions/argument_missing_exception.dart';
import 'package:reddit_2_video/utils/prettify.dart';

abstract class Command {
  final ArgParser? parser;

  void printHelp({
    String defaultsColourCode = Prettify.yellow,
    String optionsColourCode = Prettify.magenta,
    String flagsColourCode = Prettify.green,
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
          match[0]!, '$defaultsColourCode${match[0]}${Prettify.reset}');
    }
    for (final match in sqBracketsRegex.allMatches(usage)) {
      if (match[0] != '[no-]') {
        usage = usage.replaceAll(
            match[0]!, '$optionsColourCode${match[0]}${Prettify.reset}');
      }
    }
    for (final match in dashRegex.allMatches(usage)) {
      usage = usage.replaceAll(match[0]!, '$flagsColourCode${match[0]}\x1b[0m');
    }
    print(usage);
  }

  Command(this.parser);
}
