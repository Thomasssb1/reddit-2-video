import 'package:reddit_2_video/utils/globals.dart' show prePath;
import 'package:reddit_2_video/utils/run.dart';

pollyPutLexeme() async {
  await runCommand(
      'aws',
      [
        'polly',
        'put-lexicon',
        '--name',
        'AITA',
        '--content',
        'defaults/lexicon.xml'
      ],
      true,
      workingDirectory: prePath);
}
