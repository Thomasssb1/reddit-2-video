import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/config_item.dart';
import 'package:test/test.dart';

class _TestConfigItem extends ConfigItem {
  _TestConfigItem({required super.path});
  _TestConfigItem.fromFile(File file) : super.fromFile(file);
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_item_test_');
    AppPaths.initForTest(tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ConfigItem', () {
    test('constructor resolves relative path through AppPaths', () {
      final file = File('${tempDir.path}/defaults/test.txt');
      file.createSync(recursive: true);

      final item = _TestConfigItem(path: 'defaults/test.txt');

      expect(item.path.path, file.path);
    });

    test('fromFile stores the given file path', () {
      final file = File('${tempDir.path}/defaults/test.txt');
      file.createSync(recursive: true);

      final item = _TestConfigItem.fromFile(file);

      expect(item.path.path, file.path);
    });

    test('path setter accepts an existing file', () {
      final first = File('${tempDir.path}/defaults/one.txt');
      final second = File('${tempDir.path}/defaults/two.txt');
      first.createSync(recursive: true);
      second.createSync(recursive: true);

      final item = _TestConfigItem(path: 'defaults/one.txt');
      item.path = second;

      expect(item.path.path, second.path);
    });
  });
}
