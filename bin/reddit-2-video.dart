import 'package:args/args.dart';
import 'package:reddit_2_video/ffmpeg/command.dart';
import 'package:reddit_2_video/ffmpeg/execute.dart';
import 'package:reddit_2_video/subtitles/align.dart';
import 'package:reddit_2_video/subtitles/generate.dart';
import 'dart:io';
import 'package:reddit_2_video/utils/log.dart';
import 'package:reddit_2_video/get_data.dart';
import 'package:reddit_2_video/cmd.dart';
import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/ffmpeg/video.dart';
import 'package:reddit_2_video/utils/cleanup.dart';
import 'package:reddit_2_video/utils/install.dart';
import 'package:reddit_2_video/tts/aws.dart';
import 'dart:convert';

/// [enable preview ffplay]
/// [add styling to title and fade in etc using .ass]
//
void main(
  List<String> arguments,
) async {
  // delete .gitkeep so that it isn't counted when getting all tts files
  if (await File('$prePath/.temp/tts/.gitkeep').exists()) {
    await File('$prePath/.temp/tts/.gitkeep').delete().catchError((error) {
      printError(
          "Something went wrong when trying to delete a temporary file. To fix this you can go to the ./reddit-2-video/.temp/tts folder and delete the .gitkeep file. Error: $error");
      exit(1);
    });
  }

  bool awsCLIInstalled = await checkInstall('aws');
  if (!awsCLIInstalled) {
    printError("You need to install AWS CLI in order to use AWS-Polly TTS.");
    print(
        "You can find out how to do this here:\nhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions");
    exit(0);
  }

  await getBackgroundVideo();

  // get the arguments passed on command line
  var results = parse(arguments);
  ArgResults args = results['args'];

  //if (args['aws']) {
  //await pollyPutLexeme();
  //}

  // if the command was the default generation command
  if (results['command'] == null) {
    // get all post data
    final List<dynamic> postData = await getPostData(
      args['subreddit'], // subreddit
      args['sort'], // sort
      args['nsfw'], // nsfw tag
      int.parse(args['count']), // min number of comments
      args['comment-sort'], // sort for comments
      args['post-confirmation'], // check each post
      args['type'], // post type (e.g. comment or multi)
    );

    bool alternateTTS = (args['alternate'][0] == 'on' ? true : false);
    bool alternateColour = (args['alternate'][1] == 'on' ? true : false);
    String titleColour = args['alternate'][2];

    final config = await File("$prePath/defaults/config.json").readAsString();
    final json = jsonDecode(config);
    List<dynamic> voices = args['aws'] ? json['aws'] : json['accents'];
    int currentTTS = 0;
    String voice = alternateTTS ? voices[currentTTS] : args['voice'];

    // if the data collected returned nothing (e.g. subreddit has no posts)
    if (postData.isNotEmpty) {
      int counter = 0;

      for (final post in postData) {
        for (int i = 0; i < post.length; i++) {
          // if an aspect of the post doesn't contain any text
          // if ignored will produce weird noise in tts
          if (post[i].isNotEmpty) {
            bool ttsSuccess =
                await generateTTS(post[i], counter, args['ntts'], voice);

            bool alignSuccess =
                await alignSubtitles(counter, post[i], args['verbose']);

            if (!alignSuccess || !ttsSuccess) {
              exit(0);
            } else {
              counter++;
            }
          }
          currentTTS = ++currentTTS % voices.length;
        }
      }

      Duration endTime =
          await generateSubtitles(titleColour, alternateColour, args['aws']);

      bool cutSuccess = await cutVideo(endTime, args['verbose']);
      if (!cutSuccess) {
        exit(0);
      }

      List<String> command = generateCommand(args, endTime);
      bool ffmpegSuccess = await runFFMPEGCommand(command, args['output']);
      if (!ffmpegSuccess) {
        exit(0);
      }
    } else {
      // output error
      printError("No post(s) found... Try again.");
    }
    // if the command is flush
  } else if (results['command'] == 'flush') {
    // remove data from visited_log.txt
    flushLog(results['args']['post']);
    await clearTemp();
  } else if (results['command'] == 'install') {
    bool pythonInstalled = await checkInstall('python');
    if (!pythonInstalled) {
      printWarning(
          "In order to continue, you need to have python installed. Download it here: \x1b[0mhttps://www.python.org/downloads/");
    }
    bool ffmpegInstalled = await checkInstall('ffmpeg');
    if (!ffmpegInstalled) {
      await installFFmpeg(false);
    }
    bool pipInstalled = await checkInstall('pip');
    if (!pipInstalled) {
      printWarning(
          "You need to have pip installed in order to install the python dependencies");
    }
    await installPythonLibs();
  } else {
    printError(
        'There is no such command. Try again but instead use a pre-existing command, for more information run reddit-2-video --help');
  }
  exit(0);
}
