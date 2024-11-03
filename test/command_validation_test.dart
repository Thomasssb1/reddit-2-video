import 'package:test/test.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/command/parsed_command.dart';

void main() {
  List<String> defaultArguments = ["--subreddit", "AskReddit", "-d"];

  group("Command validation", () {
    group("Default command", () {
      test("No arguments", () {
        List<String> arguments = List.empty();
        expect(() => ParsedCommand.parse(arguments),
            throwsA(TypeMatcher<ArgumentMissingException>()));
      });
      test("Minimal command", () {
        List<String> arguments = [
          ...defaultArguments,
          "--subreddit",
          "AskReddit"
        ];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.defaultCommand);
        expect(results.subreddit, "AskReddit");
      });
      group("Alternate command", () {
        group("Incorrect number of options", () {
          test("No arguments", () {
            List<String> arguments = [...defaultArguments, "--alternate"];
            expect(() => ParsedCommand.parse(arguments), throwsFormatException);
          });
          test("One argument", () {
            List<String> arguments = [...defaultArguments, "--alternate=on"];
            expect(() => ParsedCommand.parse(arguments),
                throwsA(TypeMatcher<ArgumentMissingException>()));
          });
          test("Two arguments", () {
            List<String> arguments = [
              ...defaultArguments,
              "--alternate=on,off",
            ];
            expect(() => ParsedCommand.parse(arguments),
                throwsA(TypeMatcher<ArgumentMissingException>()));
          });
          test("All arguments", () {
            List<String> arguments = [
              ...defaultArguments,
              "--alternate=on,off,H0000FF",
            ];
            ParsedCommand results = ParsedCommand.parse(arguments);
            expect(results.name, Command.defaultCommand);
            expect(results.args?["alternate"].length ?? 0, 3);
          });
          test("Too many arguments", () {
            List<String> arguments = [
              ...defaultArguments,
              "--alternate=on,off,H0000FF,on",
            ];
            expect(() => ParsedCommand.parse(arguments),
                throwsA(TypeMatcher<ArgumentMissingException>()));
          });
          // test for incorrect argument types such as !on, !off and not correct colour
        });
      });
      test("Unimplemented flag used", () {
        List<String> arguments = [...defaultArguments, "--gtts"];
        expect(() => ParsedCommand.parse(arguments),
            throwsA(TypeMatcher<ArgumentNotImplementedException>()));
      });
      group("Conflicting flags used", () {
        test("AWS and GTTS flags", () {
          /*
          DOES NOT WORK AS GTTS IS CURRENTLY NOT IMPLEMENTED
          List<String> arguments = [...defaultArguments, "--aws", "--gtts"];
          expect(() => parse(arguments),
              throwsA(TypeMatcher<ArgumentConflictException>()));
          try {
            ParsedCommand results = parse(arguments);
          } on ArgumentConflictException catch (e) {
            expect(e.argument1, "aws");
            expect(e.argument2, "gtts");
          }*/
        });
      });
      group("Repeat option used", () {
        test("Invalid value used", () {
          List<String> arguments = [...defaultArguments, "--repeat", "a"];
          expect(() => ParsedCommand.parse(arguments), throwsFormatException);
        });
        test("Valid value used", () {
          List<String> arguments = [...defaultArguments, "--repeat", "1"];
          ParsedCommand results = ParsedCommand.parse(arguments);
          expect(results.name, Command.defaultCommand);
          expect(results.repeat, 1);
        });
      });
    });
    group("Help command", () {
      test("Command correctly parsed", () {
        List<String> arguments = ["--help"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.help);
        expect(results.args, null);
      });
      test("Shorthand command correctly parsed", () {
        List<String> arguments = ["-h"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.help);
        expect(results.args, null);
      });
      test("Ignore other arguments", () {
        List<String> arguments = ["--help", "--subreddit", "AskReddit"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.help);
        expect(results.args, null);
      });
    });
    group("Flush command", () {
      // Use a test log file to delete a specific post
      test("Command correctly parsed", () {
        List<String> arguments = ["flush", "--post", "1234"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.flush);
        expect(results.post, "1234");
      });
      test("Shorthand command correctly parsed", () {
        List<String> arguments = ["flush", "-p", "1234"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.flush);
        expect(results.post, "1234");
      });
      test("No arguments used", () {
        List<String> arguments = ["flush"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.flush);
        expect(results.args!.arguments.length, 1);
      });
    });
    group("Install command", () {
      test("Command correctly parsed", () {
        List<String> arguments = ["install"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.install);
        expect(results.args!.arguments.length, 1);
      });
      test("--dev command correctly parsed", () {
        List<String> arguments = ["install", "--dev"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.install);
        expect(results.isDev, true);
      });
      test("Shorthand dev command correctly parsed", () {
        List<String> arguments = ["install", "-d"];
        ParsedCommand results = ParsedCommand.parse(arguments);
        expect(results.name, Command.install);
        expect(results.isDev, true);
      });
    });
  });
}
