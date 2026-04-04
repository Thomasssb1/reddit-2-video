import 'dart:io';

import 'package:mocktail/mocktail.dart';
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
      final processMock = MockProcess();
      when(() => processMock.exitCode).thenAnswer((_) async => 0);

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
        return processMock;
      });

      final process = await Subprocess.start('ffmpeg', ['-version'],
          mode: ProcessStartMode.inheritStdio);
      expect(invoked, isTrue);
      expect(await process.exitCode, 0);
    });
  });
}
