import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('build_release.dart', () {
    test(
      'creates packaged release structure with defaults and temp files',
      () async {
        final outputRoot = Directory.systemTemp.createTempSync(
          'build_release_test_',
        );
        outputRoot.deleteSync(recursive: true);

        addTearDown(() {
          if (outputRoot.existsSync()) {
            outputRoot.deleteSync(recursive: true);
          }
        });

        final result = await Process.run(
            'dart',
            [
              'run',
              'tool/build_release.dart',
              '--output-root',
              outputRoot.path,
              '--skip-compile',
            ],
            workingDirectory: Directory.current.path);

        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        expect(Directory(p.join(outputRoot.path, 'bin')).existsSync(), isTrue);
        expect(
          Directory(p.join(outputRoot.path, 'defaults')).existsSync(),
          isTrue,
        );
        expect(
          File(
            p.join(outputRoot.path, '.temp', 'visited_log.json'),
          ).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(outputRoot.path, 'defaults', 'default.ass')).existsSync(),
          isTrue,
        );
      },
    );

    test('refuses to use the repository root as output', () async {
      final result = await Process.run(
          'dart',
          [
            'run',
            'tool/build_release.dart',
            '--output-root',
            '.',
            '--skip-compile',
          ],
          workingDirectory: Directory.current.path);

      expect(result.exitCode, isNonZero);
      expect(
        result.stderr.toString(),
        contains("You can't use the repository root as --output-root"),
      );
    });
  });
}
