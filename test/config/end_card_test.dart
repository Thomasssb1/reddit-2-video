import 'dart:io';

import 'package:reddit_2_video/config/end_card.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

void main() {
  late EndCard endCard;

  setUp(() {
    endCard = MockEndCard();
  });

  test("Check end card file duration is 2s", () {
    when(() => endCard.duration).thenReturn(Duration(seconds: 2));
    expect(endCard.duration, Duration(seconds: 2));
  });

  test("Check end card file path is correct", () {
    File mockfile = MockFile();
    EndCard endCard = EndCard(
        path: "endcard.gif",
        prePath: "/path/to/end-card/",
        fileFactory: (_, __) => mockfile);

    when(() => mockfile.path).thenReturn("/path/to/end-card/endcard.gif");
    expect(endCard.path.path, "/path/to/end-card/endcard.gif");
  });
}
