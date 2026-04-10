import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

const outputRootOption = 'output-root';
const executableNameOption = 'executable-name';
const skipCompileFlag = 'skip-compile';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      outputRootOption,
      mandatory: true,
      help:
          'Directory where the packaged reddit-2-video folder will be created.',
    )
    ..addOption(
      executableNameOption,
      defaultsTo: Platform.isWindows ? 'reddit-2-video.exe' : 'reddit-2-video',
      help: 'Executable name to place under bin/.',
    )
    ..addFlag(
      skipCompileFlag,
      negatable: false,
      help: 'Prepare the release directory without compiling the executable.',
    );

  final results = parser.parse(args);
  final repoRoot = Directory.current.absolute;
  final outputRootInput = results.option(outputRootOption)!;
  final outputRoot = Directory(outputRootInput).absolute;
  final executableName = results.option(executableNameOption)!;
  final skipCompile = results.flag(skipCompileFlag);

  _validateOutputRoot(repoRoot: repoRoot, outputRoot: outputRoot);

  if (outputRoot.existsSync()) {
    outputRoot.deleteSync(recursive: true);
  }

  final binDir = Directory(p.join(outputRoot.path, 'bin'))
    ..createSync(recursive: true);
  final tempDir = Directory(p.join(outputRoot.path, '.temp'))
    ..createSync(recursive: true);
  final defaultsDir = Directory(p.join(outputRoot.path, 'defaults'));

  _copyDirectory(Directory(p.join(repoRoot.path, 'defaults')), defaultsDir);
  File(
    p.join(repoRoot.path, '.temp', 'visited_log.json'),
  ).copySync(p.join(tempDir.path, 'visited_log.json'));

  if (!skipCompile) {
    final compileResult = await Process.run(
        'dart',
        [
          'compile',
          'exe',
          'bin/reddit-2-video.dart',
          '--output=${p.join(binDir.path, executableName)}',
        ],
        workingDirectory: repoRoot.path);

    stdout.write(compileResult.stdout);
    stderr.write(compileResult.stderr);

    if (compileResult.exitCode != 0) {
      exit(compileResult.exitCode);
    }
  }
}

void _validateOutputRoot({
  required Directory repoRoot,
  required Directory outputRoot,
}) {
  final repoPath = p.normalize(repoRoot.path);
  final outputPath = p.normalize(outputRoot.path);

  if (outputPath == repoPath) {
    throw ArgumentError(
      "You can't use the repository root as --output-root. Use a dedicated directory such as build/reddit-2-video.",
    );
  }

  if (p.isWithin(outputPath, repoPath)) {
    throw ArgumentError(
      "You can't use a parent of the repository as --output-root.",
    );
  }
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);

  for (final entity in source.listSync(recursive: false)) {
    final targetPath = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    }
  }
}
