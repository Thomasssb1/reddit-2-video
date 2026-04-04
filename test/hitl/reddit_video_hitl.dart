import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:overseer/overseer.dart';
import 'package:path/path.dart' as path;
import 'package:reddit_2_video/app_paths.dart';

Future<void> main(List<String> args) async {
  final repoRoot = detectRepositoryRoot();
  AppPaths.initForTest(repoRoot);
  final parsedArgs = parseHitlArgs(args);
  final matrixPath = resolveFromRoot(repoRoot, parsedArgs.matrixPath);
  final cleanupState = _CleanupState();

  Future<void> cleanup() => _cleanupTempDirectory(
        repoRoot,
        enabled: parsedArgs.cleanupOnExit,
        showOutput: parsedArgs.showOutput,
        cleanupState: cleanupState,
      );

  _installCleanupOnTermination(cleanup);

  try {
    final runner = OverseerRunner(
      matrixPath: matrixPath,
      outputDir: path.join(repoRoot.path, 'test', 'hitl'),
      autoOpen: true,
      generator: (testCase) async {
        final label = _requiredParam(testCase, 'label');
        final subreddit = _requiredParam(testCase, 'subreddit');
        final type = _requiredParam(testCase, 'type');
        final count = _requiredParam(testCase, 'count');
        final output = _requiredParam(testCase, 'output');
        final sort = _requiredParam(testCase, 'sort');
        final voice = _requiredParam(testCase, 'voice');
        final resolvedOutputPath = resolveFromRoot(repoRoot, output);

        await Directory(path.join(repoRoot.path, 'test', 'hitl'))
            .create(recursive: true);
        await Directory(path.join(repoRoot.path, '.temp', 'hitl'))
            .create(recursive: true);

        if (parsedArgs.flushFirst) {
          final flushArgs = [
            'run',
            'bin/reddit-2-video.dart',
            'flush',
            '--dev'
          ];
          final flush = await _runCommandWithStreaming(
            executable: 'dart',
            arguments: flushArgs,
            workingDirectory: repoRoot.path,
            label: 'flush',
            showOutput: parsedArgs.showOutput,
          );

          if (flush.exitCode != 0) {
            throw ProcessException(
              'dart',
              flushArgs,
              'Failed to prepare environment for HITL run.\n'
                  'stdout:\n${flush.stdout}\n'
                  'stderr:\n${flush.stderr}',
              flush.exitCode,
            );
          }
        }

        final horror = _optionalBoolParam(testCase, 'horror');
        final youtubeShort = _optionalBoolParam(testCase, 'youtube_short');

        final runArgs = [
          'run',
          'bin/reddit-2-video.dart',
          '--subreddit',
          subreddit,
          '--type',
          type,
          '--count',
          count,
          '--sort',
          sort,
          '--voice',
          voice,
          '--output',
          resolvedOutputPath,
          '--file-type',
          'mp4',
          '--repeat',
          '1',
          '--dev',
          '--override',
          '--verbose',
          if (horror) '--horror',
          if (youtubeShort) '--youtube-short',
        ];

        final run = await _runCommandWithStreaming(
          executable: 'dart',
          arguments: runArgs,
          workingDirectory: repoRoot.path,
          label: 'run',
          showOutput: parsedArgs.showOutput,
        );

        if (run.exitCode != 0) {
          throw ProcessException(
            'dart',
            runArgs,
            'reddit-2-video execution failed.\n'
                'stdout:\n${run.stdout}\n'
                'stderr:\n${run.stderr}',
            run.exitCode,
          );
        }

        final artifact = File(resolvedOutputPath);
        if (!artifact.existsSync()) {
          throw FileSystemException(
            'Expected generated artifact was not found.',
            resolvedOutputPath,
          );
        }

        return ArtifactResult(
          path: resolvedOutputPath,
          metadata: {
            'label': label,
            'type': type,
            'subreddit': subreddit,
            'command': 'dart ${runArgs.join(' ')}',
          },
        );
      },
    );

    await runner.run();
  } finally {
    await cleanup();
  }
}

({String matrixPath, bool flushFirst, bool showOutput, bool cleanupOnExit})
    parseHitlArgs(List<String> args) {
  const defaultMatrixPath = 'test/hitl/matrices/core.matrix.yaml';
  bool flushFirst = false;
  bool showOutput = true;
  bool cleanupOnExit = true;
  String? matrixPath;

  for (final arg in args) {
    if (arg == '--flush-first') {
      flushFirst = true;
      continue;
    }

    if (arg == '--quiet') {
      showOutput = false;
      continue;
    }

    if (arg == '--keep-temp') {
      cleanupOnExit = false;
      continue;
    }

    if (matrixPath == null) {
      matrixPath = arg;
      continue;
    }

    throw ArgumentError(
      'Unexpected extra argument "$arg". Expected at most one matrix path and optional --flush-first/--quiet/--keep-temp.',
    );
  }

  return (
    matrixPath: matrixPath ?? defaultMatrixPath,
    flushFirst: flushFirst,
    showOutput: showOutput,
    cleanupOnExit: cleanupOnExit,
  );
}

Directory detectRepositoryRoot([Directory? startDirectory]) {
  Directory current = startDirectory ?? Directory.current;

  while (true) {
    if (_isRepositoryRoot(current)) {
      return current;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw FileSystemException(
        'Unable to locate repository root from "${(startDirectory ?? Directory.current).path}".',
      );
    }

    current = parent;
  }
}

String resolveFromRoot(Directory root, String inputPath) {
  if (path.isAbsolute(inputPath)) {
    return path.normalize(inputPath);
  }

  return path.normalize(path.join(root.path, inputPath));
}

Future<ProcessResult> _runCommandWithStreaming({
  required String executable,
  required List<String> arguments,
  required String workingDirectory,
  required String label,
  required bool showOutput,
}) async {
  if (showOutput) {
    stdout.writeln('[$label] Running: $executable ${arguments.join(' ')}');
  }

  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );

  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  bool printedStdoutHeader = false;
  bool printedStderrHeader = false;

  final stdoutDone = process.stdout.transform(utf8.decoder).listen((chunk) {
    stdoutBuffer.write(chunk);
    if (showOutput && chunk.isNotEmpty) {
      if (!printedStdoutHeader) {
        stdout.writeln('[$label stdout]');
        printedStdoutHeader = true;
      }
      stdout.write(chunk);
    }
  }).asFuture<void>();

  final stderrDone = process.stderr.transform(utf8.decoder).listen((chunk) {
    stderrBuffer.write(chunk);
    if (showOutput && chunk.isNotEmpty) {
      if (!printedStderrHeader) {
        stderr.writeln('[$label stderr]');
        printedStderrHeader = true;
      }
      stderr.write(chunk);
    }
  }).asFuture<void>();

  final exitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);

  return ProcessResult(
    process.pid,
    exitCode,
    stdoutBuffer.toString(),
    stderrBuffer.toString(),
  );
}

void _installCleanupOnTermination(Future<void> Function() cleanup) {
  ProcessSignal.sigint.watch().listen((_) async {
    await cleanup();
    exit(130);
  });

  ProcessSignal.sigterm.watch().listen((_) async {
    await cleanup();
    exit(143);
  });
}

Future<void> _cleanupTempDirectory(
  Directory repoRoot, {
  required bool enabled,
  required bool showOutput,
  required _CleanupState cleanupState,
}) async {
  if (!enabled || cleanupState.hasRun) {
    return;
  }

  cleanupState.hasRun = true;
  final tempDirectory = Directory(path.join(repoRoot.path, '.temp'));

  if (!tempDirectory.existsSync()) {
    return;
  }

  await tempDirectory.delete(recursive: true);
  if (showOutput) {
    stdout.writeln('[cleanup] Deleted ${tempDirectory.path}');
  }
}

bool _isRepositoryRoot(Directory directory) {
  final pubspecFile = File(path.join(directory.path, 'pubspec.yaml'));
  final entrypointFile =
      File(path.join(directory.path, 'bin', 'reddit-2-video.dart'));
  return pubspecFile.existsSync() && entrypointFile.existsSync();
}

String _requiredParam(TestCase testCase, String key) {
  final value = testCase.params[key];
  if (value == null || value.toString().trim().isEmpty) {
    throw ArgumentError('Missing required matrix parameter: $key');
  }
  return value.toString();
}

bool _optionalBoolParam(TestCase testCase, String key) {
  final value = testCase.params[key];
  if (value == null) {
    return false;
  }

  final normalized = value.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

class _CleanupState {
  bool hasRun = false;
}
