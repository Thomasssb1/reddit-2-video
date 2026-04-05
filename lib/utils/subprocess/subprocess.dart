import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/subprocess/progress_parser.dart';

class SubprocessResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const SubprocessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });
}

class Subprocess {
  static final List<RegExp> _interactivePromptPatterns = [
    RegExp(r'overwrite\?', caseSensitive: false),
    RegExp(r'\[[yn]/[yn]\]', caseSensitive: false),
    RegExp(r'\([yn]/[yn]\)', caseSensitive: false),
    RegExp(r'(enter|type) .+:$', caseSensitive: false),
  ];
  static ProcessStartMode modeForVerbose(bool verbose) =>
      verbose ? ProcessStartMode.inheritStdio : ProcessStartMode.normal;

  static Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) _run = Process.run;

  static Future<Process> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    ProcessStartMode mode,
  }) _start = Process.start;

  static String? _resolveWorkingDirectory(String? workingDirectory) {
    if (workingDirectory != null) return workingDirectory;
    try {
      return AppPaths.rootPath;
    } on StateError {
      return null;
    }
  }

  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) =>
      _run(
        executable,
        arguments,
        workingDirectory: _resolveWorkingDirectory(workingDirectory),
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
      );

  static Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) =>
      _start(
        executable,
        arguments,
        workingDirectory: _resolveWorkingDirectory(workingDirectory),
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        mode: mode,
      );

  static Future<SubprocessResult> exec(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    bool verbose = false,
    LogSection? section,
    SubprocessProgressMode progressMode = SubprocessProgressMode.none,
    Duration? expectedDuration,
    void Function(SubprocessProgressUpdate update)? onProgress,
  }) async {
    final process = await start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final stdoutLineBuffer = StringBuffer();
    final stderrLineBuffer = StringBuffer();
    final progressParser = createSubprocessProgressParser(
      progressMode,
      expectedDuration: expectedDuration,
    );

    void emitOutput(String data, {required bool isError}) {
      if (data.isEmpty) return;
      logger.emitRaw(data, section: section, isError: isError);
    }

    void handleLine(String line, {required bool isError}) {
      final progressHandled =
          progressParser?.handleLine(line, onProgress) ?? false;
      if (progressHandled) {
        return;
      }

      if (verbose) {
        emitOutput('$line\n', isError: isError);
      }
    }

    void processChunk(String chunk, StringBuffer lineBuffer,
        {required bool isError}) {
      final normalized = chunk.replaceAll('\r', '\n');
      lineBuffer.write(normalized);
      final lines = lineBuffer.toString().split('\n');
      lineBuffer
        ..clear()
        ..write(lines.removeLast());

      for (final line in lines) {
        handleLine(line, isError: isError);
      }
    }

    void flushRemaining(StringBuffer lineBuffer, {required bool isError}) {
      final data = lineBuffer.toString();
      if (data.isEmpty) return;

      final progressHandled =
          progressParser?.handleLine(data, onProgress) ?? false;
      if (!progressHandled && _looksInteractivePrompt(data)) {
        emitOutput(data, isError: isError);
      } else if (!progressHandled && verbose) {
        emitOutput(data, isError: isError);
      }
    }

    void flushAllRemaining() {
      flushRemaining(stdoutLineBuffer, isError: false);
      flushRemaining(stderrLineBuffer, isError: true);
    }

    final stdoutDone = process.stdout.transform(utf8.decoder).listen((data) {
      stdoutBuffer.write(data);
      processChunk(data, stdoutLineBuffer, isError: false);
    }).asFuture<void>();
    final stderrDone = process.stderr.transform(utf8.decoder).listen((data) {
      stderrBuffer.write(data);
      processChunk(data, stderrLineBuffer, isError: true);
    }).asFuture<void>();

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);
    flushAllRemaining();

    return SubprocessResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  static bool _looksInteractivePrompt(String data) =>
      _interactivePromptPatterns.any((pattern) => pattern.hasMatch(data));

  static void setRunForTest(
      Future<ProcessResult> Function(
        String executable,
        List<String> arguments, {
        String? workingDirectory,
        Map<String, String>? environment,
        bool includeParentEnvironment,
        bool runInShell,
        Encoding? stdoutEncoding,
        Encoding? stderrEncoding,
      }) runHandler) {
    _run = runHandler;
  }

  static void setStartForTest(
      Future<Process> Function(
        String executable,
        List<String> arguments, {
        String? workingDirectory,
        Map<String, String>? environment,
        bool includeParentEnvironment,
        bool runInShell,
        ProcessStartMode mode,
      }) startHandler) {
    _start = startHandler;
  }

  static void setOutputSinksForTest({
    StringSink? stdoutSink,
    StringSink? stderrSink,
  }) {
    logger.setOutputSinksForTest(
      stdoutSink: stdoutSink,
      stderrSink: stderrSink,
    );
  }

  static void resetForTest() {
    _run = Process.run;
    _start = Process.start;
    logger.setOutputSinksForTest();
  }
}
