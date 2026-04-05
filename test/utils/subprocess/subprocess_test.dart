import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
import 'package:reddit_2_video/utils/subprocess/progress_parser.dart';
import 'package:test/test.dart';

import '../../mocks.dart';

void main() {
  tearDown(() {
    Subprocess.resetForTest();
    logger.resetForTest();
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

    test('exec prefixes verbose output with section label when provided',
        () async {
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

      await Subprocess.exec('ffmpeg', ['-i', 'input.mp4'],
          verbose: true, section: LogSection.generation);

      expect(stdoutBuffer.toString(), contains('[Generation]'));
      expect(stdoutBuffer.toString(), contains('progress update'));
    });

    test('exec parses ffmpeg progress updates without mirroring them',
        () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(
          exitCode: 0,
          out: 'out_time_ms=500000\nfps=24.0\nspeed=1.2x\nprogress=continue\n',
        );
      });

      final stdoutBuffer = StringBuffer();
      final updates = <SubprocessProgressUpdate>[];
      Subprocess.setOutputSinksForTest(stdoutSink: stdoutBuffer);

      await Subprocess.exec(
        'ffmpeg',
        ['-i', 'input.mp4', 'output.mp4'],
        verbose: true,
        progressMode: SubprocessProgressMode.ffmpeg,
        expectedDuration: const Duration(seconds: 1),
        onProgress: updates.add,
      );

      expect(updates, hasLength(1));
      expect(updates.first.fraction, closeTo(0.5, 0.001));
      expect(updates.first.detail, equals('fps 24.0 | speed 1.2x'));
      expect(stdoutBuffer.toString(), isNot(contains('out_time_ms=500000')));
      expect(stdoutBuffer.toString(), isNot(contains('fps=24.0')));
      expect(stdoutBuffer.toString(), isNot(contains('speed=1.2x')));
      expect(stdoutBuffer.toString(), isNot(contains('progress=continue')));
    });

    test('exec parses yt-dlp progress updates without mirroring them',
        () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(
          exitCode: 0,
          err: '[download]  25.0% of 10.00MiB at 1.00MiB/s ETA 00:07\n',
        );
      });

      final stderrBuffer = StringBuffer();
      final updates = <SubprocessProgressUpdate>[];
      Subprocess.setOutputSinksForTest(stderrSink: stderrBuffer);

      await Subprocess.exec(
        'yt-dlp',
        ['https://example.com'],
        verbose: true,
        progressMode: SubprocessProgressMode.ytDlp,
        onProgress: updates.add,
      );

      expect(updates, hasLength(1));
      expect(updates.first.fraction, closeTo(0.25, 0.001));
      expect(updates.first.detail, equals('1.00MiB/s | ETA 00:07'));
      expect(stderrBuffer.toString(), isNot(contains('[download]')));
      expect(stderrBuffer.toString(), isNot(contains('25.0%')));
      expect(stderrBuffer.toString(), isNot(contains('ETA 00:07')));
    });

    test('exec still mirrors non-progress verbose output beside progress',
        () async {
      Subprocess.setStartForTest((executable, arguments,
          {workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          mode = ProcessStartMode.normal}) async {
        return FakeProcess(
          exitCode: 0,
          err:
              '[download]  25.0% of 10.00MiB at 1.00MiB/s ETA 00:07\nwarning line\n',
        );
      });

      final stderrBuffer = StringBuffer();
      Subprocess.setOutputSinksForTest(stderrSink: stderrBuffer);

      await Subprocess.exec(
        'yt-dlp',
        ['https://example.com'],
        verbose: true,
        progressMode: SubprocessProgressMode.ytDlp,
      );

      expect(
        stderrBuffer.toString(),
        equals('warning line\n'),
      );
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
