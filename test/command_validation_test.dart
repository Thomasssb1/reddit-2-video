import 'package:reddit_2_video/cmd.dart';
import 'package:test/test.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';

void main() {
  List<String> defaultArguments = ["--subreddit", "AskReddit", "-d"];

  group("Command validation", () {
    group("Default command", () {
      test("No arguments", () {
        List<String> arguments = List.empty();
        expect(() => parse(arguments),
            throwsA(TypeMatcher<ArgumentMissingException>()));
      });
      test("Minimal command", () {
        List<String> arguments = [
          ...defaultArguments,
          "--subreddit",
          "AskReddit"
        ];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.defaultCommand);
        expect(results.args!["subreddit"], "AskReddit");
      });
      group("Alternate command", () {
        group("Incorrect number of options", () {
          test("No arguments", () {
            List<String> arguments = [...defaultArguments, "--alternate"];
            expect(() => parse(arguments), throwsFormatException);
          });
          test("One argument", () {
            List<String> arguments = [...defaultArguments, "--alternate=on"];
            expect(() => parse(arguments),
                throwsA(TypeMatcher<ArgumentMissingException>()));
          });
          test("Two arguments", () {
            List<String> arguments = [
              ...defaultArguments,
              "--alternate=on,off",
            ];
            expect(() => parse(arguments),
                throwsA(TypeMatcher<ArgumentMissingException>()));
          });
          test("All arguments", () {
            List<String> arguments = [
              ...defaultArguments,
              "--alternate=on,off,H0000FF",
            ];
            ParsedCommand results = parse(arguments);
            expect(results.command, Command.defaultCommand);
            expect(results.args?["alternate"].length ?? 0, 3);
          });
          test("Too many arguments", () {
            List<String> arguments = [
              ...defaultArguments,
              "--alternate=on,off,H0000FF,on",
            ];
            expect(() => parse(arguments),
                throwsA(TypeMatcher<ArgumentMissingException>()));
          });
          // test for incorrect argument types such as !on, !off and not correct colour
        });
      });
      test("Unimplemented flag used", () {
        List<String> arguments = [...defaultArguments, "--gtts"];
        expect(() => parse(arguments),
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
          expect(() => parse(arguments), throwsFormatException);
        });
        test("Valid value used", () {
          List<String> arguments = [...defaultArguments, "--repeat", "1"];
          ParsedCommand results = parse(arguments);
          expect(results.command, Command.defaultCommand);
          expect(results.args?["repeat"], "1");
        });
      });
    });
    group("Help command", () {
      test("Command correctly parsed", () {
        List<String> arguments = ["--help"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.help);
        expect(results.args, null);
      });
      test("Shorthand command correctly parsed", () {
        List<String> arguments = ["-h"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.help);
        expect(results.args, null);
      });
      test("Ignore other arguments", () {
        List<String> arguments = ["--help", "--subreddit", "AskReddit"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.help);
        expect(results.args, null);
      });
    });
    group("Flush command", () {
      // Use a test log file to delete a specific post
      test("Command correctly parsed", () {
        List<String> arguments = ["flush", "--post", "1234"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.flush);
        expect(results.args?["post"], "1234");
      });
      test("Shorthand command correctly parsed", () {
        List<String> arguments = ["flush", "-p", "1234"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.flush);
        expect(results.args?["post"], "1234");
      });
      test("No arguments used", () {
        List<String> arguments = ["flush"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.flush);
        expect(results.args!.arguments.length, 1);
      });
    });
    group("Install command", () {
      test("Command correctly parsed", () {
        List<String> arguments = ["install"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.install);
        expect(results.args!.arguments.length, 1);
      });
      test("--dev command correctly parsed", () {
        List<String> arguments = ["install", "--dev"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.install);
        expect(results.isDev, true);
      });
      test("Shorthand dev command correctly parsed", () {
        List<String> arguments = ["install", "-d"];
        ParsedCommand results = parse(arguments);
        expect(results.command, Command.install);
        expect(results.isDev, true);
      });
    });
  });
}
