import 'package:reddit_2_video/utils/globals.dart' show prePath;
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';

int counter = 0;

generateTTS(String text, String ttsID, bool ntts, String voice, bool censor,
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
        '.temp/$id/tts/tts-$ttsID.mp3',
      ],
      true,
      workingDirectory: prePath);
  if (ttsResult == 0) {
    counter++;
    printSuccess("\rSuccessfully generated TTS. ($counter).");
    return true;
  } else {
    printError("\rTTS could not be successfully generated. Exiting.");
    return false;
  }
}
