import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/utils/run.dart';

pollyPutLexeme() async {
  await runCommand(
      'aws', ['polly', 'put-lexicon', '--name', 'AITA', '--content', 'defaults/lexicon.xml'], true, prePath);
}
