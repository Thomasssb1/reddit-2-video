import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/app_paths.dart';

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

    final stdoutDone = process.stdout.transform(utf8.decoder).listen((data) {
      stdoutBuffer.write(data);
      if (verbose) stdout.write(data);
    }).asFuture<void>();
    final stderrDone = process.stderr.transform(utf8.decoder).listen((data) {
      stderrBuffer.write(data);
      if (verbose) stderr.write(data);
    }).asFuture<void>();

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    return SubprocessResult(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

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

  static void resetForTest() {
    _run = Process.run;
    _start = Process.start;
  }
}
