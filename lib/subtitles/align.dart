import 'dart:async';

import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';
import 'dart:io';

Future<bool> alignSubtitles(int counter, String prevText, bool verbose) async {
  StreamSubscription<String> msg = Stream<String>.empty().listen((event) {});
  if (!verbose) {
    final loadingMessage =
        Stream<String>.periodic(const Duration(seconds: 1), (secondCount) {
      return "Aligning subtitles ${secondCount + 1}s";
    });
    msg = loadingMessage.listen((text) {
      stdout.write("\r$text");
    });
  }
  int code = await runCommand(
      'whisper_timestamped',
      [
        "$prePath/.temp/tts/tts-$counter.mp3",
        '--language',
        'en',
        '--output_format',
        'json',
        '--compute_confidence',
        'False',
        if (prevText.isNotEmpty) ...[
          '--initial_prompt',
          prevText,
        ],
        '--output_dir',
        '$prePath/.temp/config'
      ],
      verbose);
  msg.cancel();
  if (code == 0) {
    printSuccess(
        "\nSubtitles have been aligned. Continuing with video generation.");
    return true;
  } else {
    printError(
        "\nSomething went wrong when trying to align subtitles. Please try again.\nIf this error persists then post it as an error on github.\nhttps://github.com/Thomasssb1/reddit-2-video/issues");
    return false;
  }
}
