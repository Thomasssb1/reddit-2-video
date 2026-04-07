import 'dart:io';

import 'package:reddit_2_video/docs/cli_docs_generator.dart';
import 'package:test/test.dart';

void main() {
  group('CliDocsGenerator', () {
    late String source;
    late CliDocsGenerator generator;

    setUp(() {
      source = File('lib/command/parsed_command.dart').readAsStringSync();
      generator = CliDocsGenerator();
    });

    test('renders command overview and source label', () {
      final markdown = generator.generateFromSource(source);

      expect(markdown, startsWith('# CLI Reference'));
      expect(
          markdown,
          contains(
              'This page is generated from `lib/command/parsed_command.dart`.'));
      expect(markdown, contains('## Command Overview'));
      expect(
          markdown, contains('reddit-2-video --subreddit AskReddit [options]'));
      expect(
          markdown, contains('reddit-2-video flush --post <reddit-post-id>'));
      expect(markdown, contains('reddit-2-video install'));
    });

    test('extracts default command option metadata', () {
      final markdown = generator.generateFromSource(source);

      expect(markdown, contains('## Default Command'));
      expect(markdown, contains('#### `--subreddit`'));
      expect(markdown, contains('- Required: yes'));

      expect(markdown, contains('#### `--sort`'));
      expect(markdown, contains('- Short flag: `-s`'));
      expect(markdown, contains('- Default: `top`'));
      expect(markdown, contains('`hot`, `new`, `top`, `rising`'));

      expect(markdown, contains('#### `--alternate`'));
      expect(markdown, contains('- Type: `multi-option`'));
      expect(
          markdown,
          contains(
              '- Value: `<alternate-tts(on/off),alternate-colour(on/off)>`'));
      expect(markdown, contains('- Default: `[off, off]`'));
      expect(markdown, contains('tts - alternate TTS voice'));

      expect(markdown, contains('#### `--title-color`'));
      expect(markdown, contains('- Value: `<RRGGBB>`'));
      expect(markdown, contains('- Default: `FF0000`'));

      expect(markdown, contains('#### `--post-confirmation`'));
      expect(markdown, contains('- Default: `false`'));

      expect(markdown, contains('#### `--nsfw`'));
      expect(markdown, contains('- Default: `true`'));

      expect(markdown, contains('#### `--max-length`'));
      expect(
          markdown,
          contains(
              'Generation stops at a logical boundary once this limit is reached.'));
    });

    test('extracts command specific sections and options', () {
      final markdown = generator.generateFromSource(source);

      expect(markdown, contains('## `install` Command'));
      expect(
          markdown, contains('Installs or bootstraps runtime dependencies.'));
      expect(
          markdown, contains('This command has no command-specific options.'));

      expect(markdown, contains('## `flush` Command'));
      expect(
          markdown,
          contains(
              'remove a post from the visited log and allow it to be reused.'));
      expect(markdown, contains('#### `--post`'));
      expect(markdown, contains('- Type: `option`'));
      expect(markdown, contains('- Short flag: `-p`'));
      expect(
          markdown,
          contains(
              '- Description: Remove a specific reddit post from the visited log.'));
    });

    test('supports custom labels and reading from file', () {
      final tempDir = Directory.systemTemp.createTempSync('cli_docs_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final sourceFile = File('${tempDir.path}/parsed_command.dart')
        ..writeAsStringSync(source);

      final customGenerator = CliDocsGenerator(
        executableName: 'r2v',
        sourcePathLabel: 'custom/parsed_command.dart',
      );

      final markdown = customGenerator.generateFromFile(sourceFile.path);

      expect(
          markdown,
          contains(
              'This page is generated from `custom/parsed_command.dart`.'));
      expect(markdown, contains('r2v --subreddit AskReddit [options]'));
      expect(markdown, contains('r2v flush --post <reddit-post-id>'));
      expect(markdown, contains('r2v install'));
      expect(markdown.endsWith('\n'), isTrue);
    });

    test('renders newly added parser commands without hardcoded support', () {
      final extendedSource = source.replaceFirst(
        "    parser.addCommand('install');",
        "    parser.addCommand('install');\n    parser.addCommand('doctor');",
      );

      final markdown = generator.generateFromSource(extendedSource);

      expect(markdown, contains('reddit-2-video doctor'));
      expect(markdown, contains('## `doctor` Command'));
      expect(
          markdown, contains('Command discovered from the parser definition.'));
      expect(markdown, isNot(contains('```bash\ndoctor')));
      expect(markdown, contains('```bash\nreddit-2-video doctor\n```'));
    });
  });
}
