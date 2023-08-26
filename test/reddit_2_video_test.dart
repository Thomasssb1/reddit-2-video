import 'package:args/args.dart';
import 'package:reddit_2_video/cmd.dart';
import 'package:test/test.dart';

void main() {
  group("CLI parsing", () {
    test("Run reddit-2-video command with subreddit arg only", () {
      var results = parse(['--subreddit', 'AskReddit']);
      ArgResults args = results['args'];

      List<String?> command = [(args.command == null) ? null : args.command.toString(), ...args.arguments];

      expect([null, '--subreddit', 'AskReddit'], command);
    });
    test("Run reddit-2-video command with url as a subreddit arg", () {
      var results =
          parse(['--subreddit', 'https://www.reddit.com/r/AskReddit/comments/15lfece/why_did_you_get_fired/']);

      ArgResults args = results['args'];

      List<String?> command = [(args.command == null) ? null : args.command.toString(), ...args.arguments];

      expect(
          [null, '--subreddit', 'https://www.reddit.com/r/AskReddit/comments/15lfece/why_did_you_get_fired/'], command);
    });
    test("Run reddit-2-video command with no subreddit arg", () {
      bool errorCaught = false;
      try {
        parse([]);
      } catch (e) {
        errorCaught = true;
      }
      expect(true, errorCaught);
    });

    test("Run reddit-2-video command with correct alternate command", () {
      var results = parse(['--subreddit', 'AskReddit', '--alternate=on,off,HFF0000']);
      expect(['on', 'off', 'HFF0000'], results['args']['alternate']);
    });

    test("Run reddit-2-video command with alternate command that has only two options", () {
      bool errorCaught = false;
      try {
        parse(['--subreddit', 'AskReddit', '--alternate=off,on']);
      } catch (e) {
        print(e);
        errorCaught = true;
      }
      expect(true, errorCaught);
    });
  });
}
