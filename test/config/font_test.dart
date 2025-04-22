import 'dart:io';
import 'package:test/test.dart';

import 'package:reddit_2_video/config/font.dart';

void main() {
  test("Check font file exists", () {
    Font font = Font.verdana(prePath: Directory.current.path);
    expect(font.path.existsSync(), true);
  });

  test("Check font size is within range", () {
    Font font = Font.verdana(prePath: Directory.current.path);
    expect(font.size, greaterThan(0));
    expect(font.size, lessThan(48));
  });

  test("Check font name is correct", () {
    Font font = Font.verdana(prePath: Directory.current.path);
    expect(font.name, 'verdana');
  });
}
