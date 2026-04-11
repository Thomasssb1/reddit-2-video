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
  final cleanupState = HitlCleanupState();

  Future<void> cleanup() => cleanupHitlTempDirectory(
        repoRoot,
        enabled: parsedArgs.cleanupOnExit,
        showOutput: parsedArgs.showOutput,
        cleanupState: cleanupState,
      );

  final terminationHandler = TerminationCleanupHandler.install(
    cleanup: cleanup,
  );

  try {
    final runner = OverseerRunner(
      matrixPath: matrixPath,
      outputDir: path.join(repoRoot.path, 'test', 'hitl'),
      autoOpen: true,
      generator: (testCase) async {
        final label = _requiredParam(testCase, 'label');
        final output = _requiredParam(testCase, 'output');
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

        final runArgs = buildRunArgs(
          testCase.params,
          outputPath: resolvedOutputPath,
        );

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
            'type': _requiredParam(testCase, 'type'),
            'subreddit': _requiredParam(testCase, 'subreddit'),
            'command': 'dart ${runArgs.join(' ')}',
          },
        );
      },
    );

    final reportPath = await runner.run();
    print('Generated report successfully: $reportPath');
  } finally {
    await terminationHandler.dispose();
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

    if (matrixPath == null) {
      matrixPath = arg;
      continue;
    }

    throw ArgumentError(
      'Unexpected extra argument "$arg". Expected at most one matrix path and optional --flush-first/--quiet.',
    );
  }

  return (
    matrixPath: matrixPath ?? defaultMatrixPath,
    flushFirst: flushFirst,
    showOutput: showOutput,
    cleanupOnExit: cleanupOnExit,
  );
}

List<String> buildRunArgs(
  Map<String, dynamic> params, {
  required String outputPath,
}) {
  final type = _requiredMapParam(params, 'type');
  final runArgs = <String>[
    'run',
    'bin/reddit-2-video.dart',
    '--subreddit',
    _requiredMapParam(params, 'subreddit'),
    '--type',
    type,
    '--count',
    _requiredMapParam(params, 'count'),
    '--sort',
    _requiredMapParam(params, 'sort'),
    if (type == 'comments') ...[
      '--comment-sort',
      _requiredMapParam(params, 'comment_sort'),
    ],
    '--title-color',
    _requiredMapParam(params, 'title-color'),
    ..._boolFlagArgs(params, key: 'nsfw', flagName: 'nsfw'),
    ..._boolFlagArgs(params, key: 'ntts', flagName: 'ntts'),
    '--voice',
    _requiredMapParam(params, 'voice'),
    '--output',
    outputPath,
    '--file-type',
    _requiredMapParam(params, 'file-type'),
    '--framerate',
    _requiredMapParam(params, 'framerate'),
    ..._boolFlagArgs(params, key: 'censor', flagName: 'censor'),
    '--repeat',
    '1',
    '--override',
    '--verbose',
  ];

  return runArgs;
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

class TerminationCleanupHandler {
  TerminationCleanupHandler._(this._subscriptions);

  final List<StreamSubscription<ProcessSignal>> _subscriptions;

  static TerminationCleanupHandler install({
    required Future<void> Function() cleanup,
    Stream<ProcessSignal>? sigintStream,
    Stream<ProcessSignal>? sigtermStream,
    void Function(int exitCode)? exitProcess,
  }) {
    final resolvedExitProcess = exitProcess ?? exit;
    final subscriptions = <StreamSubscription<ProcessSignal>>[];

    subscriptions.add(
      (sigintStream ?? ProcessSignal.sigint.watch()).listen((_) async {
        await cleanup();
        resolvedExitProcess(130);
      }),
    );

    subscriptions.add(
      (sigtermStream ?? ProcessSignal.sigterm.watch()).listen((_) async {
        await cleanup();
        resolvedExitProcess(143);
      }),
    );

    return TerminationCleanupHandler._(subscriptions);
  }

  Future<void> dispose() async {
    await Future.wait(
        _subscriptions.map((subscription) => subscription.cancel()));
  }
}

Future<void> cleanupHitlTempDirectory(
  Directory repoRoot, {
  required bool enabled,
  required bool showOutput,
  required HitlCleanupState cleanupState,
}) async {
  if (!enabled || cleanupState.hasRun) {
    return;
  }

  cleanupState.hasRun = true;
  final tempDirectory = Directory(path.join(repoRoot.path, '.temp', 'hitl'));

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

String _requiredMapParam(Map<String, dynamic> params, String key) {
  final value = params[key];
  if (value == null || value.toString().trim().isEmpty) {
    throw ArgumentError('Missing required matrix parameter: $key');
  }
  return value.toString();
}

bool? _optionalBoolMapParam(Map<String, dynamic> params, String key) {
  final value = params[key];
  if (value == null) {
    return null;
  }

  final normalized = value.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

List<String> _boolFlagArgs(
  Map<String, dynamic> params, {
  required String key,
  required String flagName,
}) {
  final value = _optionalBoolMapParam(params, key);
  if (value == null) {
    return const [];
  }

  return [value ? '--$flagName' : '--no-$flagName'];
}

class HitlCleanupState {
  bool hasRun = false;
}
