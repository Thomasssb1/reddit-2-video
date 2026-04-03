import 'package:args/args.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
import 'package:test/test.dart';

/// Builds a minimal [ArgResults] from a list of CLI args, returning a
/// [ParsedCommand] in default-command mode.
ParsedCommand _build(List<String> args) {
  return ParsedCommand.parse(['--subreddit', 'AskReddit', ...args]);
}

void main() {
  group('ParsedCommand.parse', () {
    group('required arguments', () {
      test('throws ArgumentMissingException when --subreddit is absent', () {
        expect(
          () => ParsedCommand.parse([]),
          throwsA(isA<ArgumentMissingException>()),
        );
      });

      test('throws when --alternate has wrong count', () {
        expect(
          () => ParsedCommand.parse([
            '--subreddit',
            'AskReddit',
            '--alternate',
            'on',
          ]),
          throwsA(isA<ArgumentMissingException>()),
        );
      });

      test('throws FormatException when --repeat is not an integer', () {
        expect(
          () => ParsedCommand.parse([
            '--subreddit',
            'AskReddit',
            '--repeat',
            'abc',
          ]),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('default values', () {
      late ParsedCommand cmd;
      setUp(() => cmd = _build([]));

      test('sort defaults to top', () => expect(cmd.sort.name, 'top'));
      test('commentCount defaults to 8', () => expect(cmd.commentCount, 8));
      test('override defaults to false', () => expect(cmd.override, false));
      test('horror defaults to false', () => expect(cmd.horror, false));
      test('youtubeShort defaults to false',
          () => expect(cmd.youtubeShort, false));
      test(
          'fileType defaults to mp4', () => expect(cmd.fileType, FileType.mp4));
      test('output defaults to final', () => expect(cmd.output, 'final'));
      test('delay defaults to 1 second',
          () => expect(cmd.delay, Duration(seconds: 1)));
      test('endCardLength is null when not supplied',
          () => expect(cmd.endCardLength, isNull));
      test('maxLength is null when not supplied',
          () => expect(cmd.maxLength, isNull));
    });

    group('new parameter getters', () {
      test('delay returns correct Duration', () {
        final cmd = _build(['--delay', '3']);
        expect(cmd.delay, Duration(seconds: 3));
      });

      test('endCardLength returns correct Duration', () {
        final cmd = _build(['--end-card-length', '7']);
        expect(cmd.endCardLength, Duration(seconds: 7));
      });

      test('maxLength returns correct Duration', () {
        final cmd = _build(['--max-length', '120']);
        expect(cmd.maxLength, Duration(seconds: 120));
      });

      test('maxLength returns null when set to false', () {
        final cmd = _build(['--max-length', 'false']);
        expect(cmd.maxLength, isNull);
      });
    });

    group('framerate getter', () {
      test('returns correct FPS for 30', () {
        final cmd = _build(['--framerate', '30']);
        expect(cmd.framerate, FPS.fps30);
      });

      test('returns correct FPS for 60', () {
        final cmd = _build(['--framerate', '60']);
        expect(cmd.framerate, FPS.fps60);
      });
    });

    group('command routing', () {
      test('parse returns flush command', () {
        final cmd = ParsedCommand.parse(['flush']);
        expect(cmd.name, CommandType.flush);
      });

      test('parse returns install command', () {
        final cmd = ParsedCommand.parse(['install']);
        expect(cmd.name, CommandType.install);
      });

      test('help flag returns help command', () {
        final cmd = ParsedCommand.parse(['--help']);
        expect(cmd.name, CommandType.help);
      });
    });
  });
}
