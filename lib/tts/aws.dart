import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';

generateTTS(String text, int counter, bool ntts, String voice, bool censor,
    String id) async {
  var ttsResult = await runCommand(
      'aws',
      [
        'polly',
        'synthesize-speech',
        '--output-format',
        'mp3',
        '--voice-id',
        voice,
        '--text',
        text,
        '--engine',
        ntts ? "neural" : "standard",
        if (censor) '--lexicon-name=censor',
        '.temp/$id/tts/tts-${counter}.mp3',
      ],
      true,
      prePath);
  if (ttsResult == 0) {
    printSuccess("\rSuccessfully generated TTS. (${counter + 1}).");
    return true;
  } else {
    printError("\rTTS could not be successfully generated. Exiting.");
    return false;
  }
}
