import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:test/test.dart';

/// Builds a minimal [ArgResults] from a list of CLI args, returning a
/// [ParsedCommand] in default-command mode.
ParsedCommand _build(List<String> args) {
  return ParsedCommand.parse(['--subreddit', 'AskReddit', ...args]);
}

String _capturePrint(void Function() action) {
  final output = <String>[];

  runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, String line) {
        output.add(line);
      },
    ),
  );

  return output.join('\n');
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('parsed_command_test_');
    AppPaths.initForTest(tempDir);
    File('${tempDir.path}/song.mp3').createSync();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ParsedCommand.parse', () {
    group('required arguments', () {
      test('throws when an unknown flag is provided', () {
        expect(
          () => ParsedCommand.parse([
            '--subreddit',
            'AskReddit',
            '--unknown-flag',
          ]),
          throwsA(isA<ArgParserException>()),
        );
      });

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

      test('throws when --music has more than two values', () {
        expect(
          () => ParsedCommand.parse([
            '--subreddit',
            'AskReddit',
            '--music',
            'song.mp3,0.5,extra',
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

    group('count warning behavior', () {
      test('warns for link input when type is post', () {
        final stdoutBuffer = StringBuffer();
        logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

        expect(
          () => ParsedCommand.parse([
            '--subreddit',
            'https://www.reddit.com/r/AskReddit/comments/abc123/title/',
            '--type',
            'post',
            '--count',
            '3',
          ]),
          returnsNormally,
        );
        expect(stdoutBuffer.toString(),
            contains('--count does not work with a link'));
      });

      test('keeps count for link input when type is comments', () {
        final cmd = ParsedCommand.parse([
          '--subreddit',
          'https://www.reddit.com/r/AskReddit/comments/abc123/title/',
          '--type',
          'comments',
          '--count',
          '3',
        ]);

        expect(cmd.commentCount, 3);
      });
    });

    group('new parameter getters', () {
      test('commentSort returns correct enum for valid input', () {
        final cmd = _build(['--comment-sort', 'controversial']);
        expect(cmd.commentSort.name, 'controversial');
      });

      test('throws when commentSort input is invalid', () {
        expect(
          () => _build(['--comment-sort', 'invalid-sort']),
          throwsA(isA<ArgParserException>()),
        );
      });

      test('type returns correct enum for valid input', () {
        final cmd = _build(['--type', 'multi']);
        expect(cmd.type, RedditVideoType.multi);
      });

      test('throws when type input is invalid', () {
        expect(
          () => _build(['--type', 'invalid-type']),
          throwsA(isA<ArgParserException>()),
        );
      });

      test('alternate returns true values for valid input', () {
        final cmd = _build(['--alternate', 'on,on']);
        expect(cmd.alternate.tts, isTrue);
        expect(cmd.alternate.color, isTrue);
      });

      test('alternate treats unknown values as false', () {
        final cmd = _build(['--alternate', 'maybe,nope']);
        expect(cmd.alternate.tts, isFalse);
        expect(cmd.alternate.color, isFalse);
      });

      test('titleColor returns .ass formatted value for valid input', () {
        final cmd = _build(['--title-color', '112233']);
        expect(cmd.titleColor.toString(), r'\1c&H332211');
      });

      test('throws when titleColor input is invalid', () {
        expect(
          () => _build(['--title-color', 'not-a-colour']).titleColor,
          throwsA(isA<FormatException>()),
        );
      });

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

      test('music parses typed volume from cli', () {
        final cmd = _build(['--music', 'song.mp3,0.25']);
        final music = cmd.music;

        expect(music, isNotNull);
        expect(music!.volume, 0.25);
        expect(music.path.path, contains('song.mp3'));
      });

      test('music defaults volume to 1.0 when omitted', () {
        final cmd = _build(['--music', 'song.mp3']);
        final music = cmd.music;

        expect(music, isNotNull);
        expect(music!.volume, 1.0);
      });

      test('music falls back to 1.0 when volume is invalid', () {
        final cmd = _build(['--music', 'song.mp3,not-a-double']);
        final music = cmd.music;

        expect(music, isNotNull);
        expect(music!.volume, 1.0);
      });

      test('outputFile appends fileType when output has no extension', () {
        final cmd = _build(['--output', 'output']);

        expect(cmd.outputFile(1).path, p.join(tempDir.path, 'output.mp4'));
      });

      test('outputFile appends repeat index when repeat is greater than 1', () {
        final cmd = _build(['--output', 'video.mp4', '--repeat', '3']);

        expect(cmd.outputFile(2).path, p.join(tempDir.path, 'video-2.mp4'));
      });

      test('endCard returns resolved item when file exists', () async {
        final endCardFile = File(p.join(tempDir.path, 'end-card.png'))
          ..createSync();
        final cmd = _build([
          '--end-card',
          'end-card.png',
          '--end-card-length',
          '5',
        ]);

        final endCard = await cmd.endCard;

        expect(endCard, isNotNull);
        expect(endCard!.path.path, endCardFile.path);
        expect(endCard.duration, const Duration(seconds: 5));
      });
    });

    group('output collision validation', () {
      test(
          'throws when target output file already exists and override is false',
          () {
        File('${tempDir.path}/final.mp4').createSync();
        final cmd = _build([]);

        expect(
          () => cmd.validateOutputFilesAvailable(),
          throwsA(
            isA<OutputFileExistsException>().having(
              (exception) => exception.file.path,
              'file.path',
              p.join(tempDir.path, 'final.mp4'),
            ),
          ),
        );
      });

      test('throws when any repeated output file already exists', () {
        File('${tempDir.path}/video-2.mp4').createSync();
        final cmd = _build(['--output', 'video.mp4', '--repeat', '3']);

        expect(
          () => cmd.validateOutputFilesAvailable(),
          throwsA(
            isA<OutputFileExistsException>().having(
              (exception) => exception.file.path,
              'file.path',
              p.join(tempDir.path, 'video-2.mp4'),
            ),
          ),
        );
      });

      test('does not throw when override is enabled', () {
        File('${tempDir.path}/final.mp4').createSync();
        final cmd = _build(['--override']);

        expect(() => cmd.validateOutputFilesAvailable(), returnsNormally);
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

      test('flush command parses --post option', () {
        final cmd = ParsedCommand.parse([
          'flush',
          '--post',
          'https://www.reddit.com/r/AskReddit/comments/abc123/title/',
        ]);

        expect(cmd.name, CommandType.flush);
        expect(
          cmd.post,
          'https://www.reddit.com/r/AskReddit/comments/abc123/title/',
        );
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

    group('Command.printHelp', () {
      test('throws ArgumentMissingException when parser is null', () {
        final command = ParsedCommand.none();

        expect(
          () => command.printHelp(),
          throwsA(isA<ArgumentMissingException>()),
        );
      });

      test('prints formatted parser usage', () {
        final parser = ParsedCommand.getParser();
        final command = ParsedCommand.noArgs(
          command: CommandType.help,
          parser: parser,
        );

        final actual = _capturePrint(() {
          command.printHelp(
            defaultsColourCode: '<default>',
            optionsColourCode: '<option>',
            flagsColourCode: '<flag>',
          );
        });

        var expected = parser.usage;
        final bracketsRegex = RegExp(r'\((defaults.+)\)');
        final sqBracketsRegex = RegExp(r'\[(.*?)\]');
        final dashRegex = RegExp(r'(?!-level|-colour|-domain)(\-\S+)');

        for (final match in bracketsRegex.allMatches(expected)) {
          expected = expected.replaceAll(
            match[0]!,
            '<default>${match[0]}$ansiReset',
          );
        }
        for (final match in sqBracketsRegex.allMatches(expected)) {
          if (match[0] != '[no-]') {
            expected = expected.replaceAll(
              match[0]!,
              '<option>${match[0]}$ansiReset',
            );
          }
        }
        for (final match in dashRegex.allMatches(expected)) {
          expected = expected.replaceAll(
            match[0]!,
            '<flag>${match[0]}$ansiReset',
          );
        }

        expect(actual, expected);
      });
    });
  });
}
