import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:reddit_2_video/app_paths.dart';
import 'package:test/test.dart';

void main() {
  group('AppPaths', () {
    test('throws StateError when accessed before init', () {
      expect(
        () => AppPaths.resolve('defaults/default.ass'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'AppPaths.init() must be called before accessing paths',
          ),
        ),
      );
    });

    test('resolves paths after initForTest', () {
      final root = Directory.systemTemp.createTempSync('app_paths_test_');
      addTearDown(() {
        root.deleteSync(recursive: true);
      });

      AppPaths.initForTest(root);

      expect(AppPaths.rootPath, root.path);
      expect(
        AppPaths.resolve('defaults/default.ass').path,
        p.join(root.path, 'defaults/default.ass'),
      );
      expect(
        AppPaths.resolveDir('.temp/test').path,
        p.join(root.path, '.temp/test'),
      );
    });

    test('keeps absolute file paths unchanged', () {
      final root = Directory.systemTemp.createTempSync('app_paths_test_');
      addTearDown(() {
        root.deleteSync(recursive: true);
      });

      AppPaths.initForTest(root);

      final absolute = p.join(root.path, 'absolute_file.txt');
      expect(AppPaths.resolve(absolute).path, absolute);
    });

    test('keeps absolute directory paths unchanged', () {
      final root = Directory.systemTemp.createTempSync('app_paths_test_');
      addTearDown(() {
        root.deleteSync(recursive: true);
      });

      AppPaths.initForTest(root);

      final absolute = p.join(root.path, 'absolute_dir');
      expect(AppPaths.resolveDir(absolute).path, absolute);
    });
  });
}
