import 'dart:io';
import 'package:test/test.dart';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/font.dart';

void main() {
  setUp(() {
    AppPaths.initForTest(Directory.current);
  });

  test("Check font file exists", () {
    Font font = Font.verdana();
    expect(font.path.existsSync(), true);
  });

  test("Check font size is within range", () {
    Font font = Font.verdana();
    expect(font.size, greaterThan(0));
    expect(font.size, lessThan(48));
  });

  test("Check font name is correct", () {
    Font font = Font.verdana();
    expect(font.name, 'verdana');
  });
}
