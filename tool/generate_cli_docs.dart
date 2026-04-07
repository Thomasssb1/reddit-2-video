import 'dart:io';

import 'package:reddit_2_video/docs/cli_docs_generator.dart';

void main(List<String> args) {
  final source = File('lib/command/parsed_command.dart');
  final output = File('docs/cli.md');

  final generator = CliDocsGenerator(sourcePathLabel: source.path);
  final markdown = generator.generateFromFile(source.path);

  output.parent.createSync(recursive: true);
  output.writeAsStringSync(markdown);

  stdout.writeln('Generated ${output.path} from ${source.path}.');
}
