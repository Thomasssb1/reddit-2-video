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

  test("Check end card duration is returned", () {
    when(() => endCard.duration).thenReturn(Duration(seconds: 2));
    expect(endCard.duration, Duration(seconds: 2));
  });

  test("Check end card file path is correct", () async {
    File mockfile = MockFile();
    when(() => mockfile.path).thenReturn("/path/to/end-card/endcard.gif");

    EndCard result = await EndCard.create(
        path: "endcard.gif",
        prePath: "/path/to/end-card/",
        fileFactory: (_, __) => mockfile);

    expect(result.path.path, "/path/to/end-card/endcard.gif");
  });

  test("Check end card uses override duration for image", () async {
    File mockfile = MockFile();
    when(() => mockfile.path).thenReturn("/path/to/image.png");

    EndCard result = await EndCard.create(
        path: "image.png",
        prePath: "/path/to/",
        durationOverride: Duration(seconds: 8),
        fileFactory: (_, __) => mockfile);

    expect(result.duration, Duration(seconds: 8));
  });

  test("Check end card falls back to 5s default for image with no override",
      () async {
    File mockfile = MockFile();
    when(() => mockfile.path).thenReturn("/path/to/image.jpg");

    EndCard result = await EndCard.create(
        path: "image.jpg",
        prePath: "/path/to/",
        fileFactory: (_, __) => mockfile);

    expect(result.duration, Duration(seconds: 5));
  });
}
