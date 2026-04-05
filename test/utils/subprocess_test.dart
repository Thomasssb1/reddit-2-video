import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/utils/subprocess.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  tearDown(() {
    Subprocess.resetForTest();
  });

  group('Subprocess', () {
    test('uses injected run handler', () async {
      var invoked = false;
      Subprocess.setRunForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          stdoutEncoding,
          stderrEncoding}) async {
        invoked = true;
        expect(executable, 'yt-dlp');
        expect(arguments, ['--version']);
        return ProcessResult(0, 0, 'ok', '');
      });

      final result = await Subprocess.run('yt-dlp', ['--version']);
      expect(invoked, isTrue);
      expect(result.exitCode, 0);
      expect(result.stdout, 'ok');
    });

    test('uses injected start handler', () async {
      var invoked = false;

      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        invoked = true;
        expect(executable, 'ffmpeg');
        expect(arguments, ['-version']);
        expect(mode, ProcessStartMode.inheritStdio);
        return FakeProcess(exitCode: 0);
      });

      final process = await Subprocess.start('ffmpeg', ['-version'],
          mode: ProcessStartMode.inheritStdio);
      expect(invoked, isTrue);
      expect(await process.exitCode, 0);
    });

    test('exec captures stdout and stderr', () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        expect(executable, 'yt-dlp');
        expect(arguments, ['--version']);
        return FakeProcess(exitCode: 0, out: 'out', err: 'err');
      });

      final result = await Subprocess.exec('yt-dlp', ['--version']);
      expect(result.exitCode, 0);
      expect(result.stdout, 'out');
      expect(result.stderr, 'err');
    });

    test('exec mirrors interactive prompts from stderr when verbose is false',
        () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(
            exitCode: 0,
            err: "File 'final.mp4' already exists. Overwrite? [y/N] ");
      });

      final stderrBuffer = StringBuffer();
      Subprocess.setOutputSinksForTest(stderrSink: stderrBuffer);

      await Subprocess.exec('ffmpeg', ['-i', 'input.mp4']);

      expect(
        stderrBuffer.toString(),
        contains("Overwrite? [y/N]"),
      );
    });

    test('exec does not mirror non-prompt stderr when verbose is false',
        () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(exitCode: 0, err: 'regular diagnostic output');
      });

      final stderrBuffer = StringBuffer();
      Subprocess.setOutputSinksForTest(stderrSink: stderrBuffer);

      await Subprocess.exec('ffmpeg', ['-i', 'input.mp4']);

      expect(stderrBuffer.toString(), isEmpty);
    });

    test('exec mirrors enter or type prompts from stderr when verbose is false',
        () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(exitCode: 0, err: 'Type selection:');
      });

      final stderrBuffer = StringBuffer();
      Subprocess.setOutputSinksForTest(stderrSink: stderrBuffer);

      await Subprocess.exec('ffmpeg', ['-i', 'input.mp4']);

      expect(stderrBuffer.toString(), contains('Type selection:'));
    });

    test('exec mirrors stdout when verbose is true', () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(exitCode: 0, out: 'progress update');
      });

      final stdoutBuffer = StringBuffer();
      Subprocess.setOutputSinksForTest(stdoutSink: stdoutBuffer);

      await Subprocess.exec('ffmpeg', ['-i', 'input.mp4'], verbose: true);

      expect(stdoutBuffer.toString(), contains('progress update'));
    });

    test('uses AppPaths.rootPath as default working directory when available',
        () async {
      final root = Directory.systemTemp.createTempSync('subprocess_test_');
      addTearDown(() {
        root.deleteSync(recursive: true);
      });
      AppPaths.initForTest(root);

      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        expect(workingDirectory, root.path);
        return FakeProcess(exitCode: 0);
      });

      final result = await Subprocess.exec('yt-dlp', ['--version']);
      expect(result.exitCode, 0);
    });

    test('explicit working directory overrides AppPaths.rootPath', () async {
      final root = Directory.systemTemp.createTempSync('subprocess_test_');
      final override = Directory.systemTemp.createTempSync('subprocess_test_');
      addTearDown(() {
        root.deleteSync(recursive: true);
        override.deleteSync(recursive: true);
      });
      AppPaths.initForTest(root);

      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        expect(workingDirectory, override.path);
        return FakeProcess(exitCode: 0);
      });

      final result = await Subprocess.exec('yt-dlp', ['--version'],
          workingDirectory: override.path);
      expect(result.exitCode, 0);
    });
  });
}
