import 'package:args/args.dart';
import 'package:reddit_2_video/exceptions/no_command_exception.dart';
import 'package:reddit_2_video/ffmpeg/command.dart';
import 'package:reddit_2_video/ffmpeg/execute.dart';
import 'package:reddit_2_video/ffmpeg/splitter.dart';
import 'package:reddit_2_video/subtitles/align.dart';
import 'package:reddit_2_video/subtitles/generate.dart';
import 'package:reddit_2_video/tts/split.dart';
import 'package:reddit_2_video/utils/globals.dart';
import 'dart:io';
import 'package:reddit_2_video/utils/log.dart';
import 'package:reddit_2_video/get_data.dart';
import 'package:reddit_2_video/command/parse.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/ffmpeg/video.dart';
import 'package:reddit_2_video/utils/cleanup.dart';
import 'package:reddit_2_video/utils/install.dart';
import 'package:reddit_2_video/tts/aws.dart';
import 'dart:convert';
import 'package:reddit_2_video/utils/http.dart';
import 'package:reddit_2_video/utils/remove_characters.dart';
import 'package:reddit_2_video/utils/globals.dart' show prePath;
import 'package:reddit_2_video/command/parsed_command.dart';

// [enable preview ffplay]
void main(
  List<String> arguments,
) async {
  bool awsCLIInstalled = await checkInstall('aws');
  if (!awsCLIInstalled) {
    printError("You need to install AWS CLI in order to use AWS-Polly TTS.");
    print(
        "You can find out how to do this here:\nhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions");
    exit(0);
  }

  // get the arguments passed on command line
  try {
    ParsedCommand results = parse(arguments);

    // for now use static
    int endCardLength = 2;

    // set prepath based on --dev flag
    assert(results.isDev, true);
    prePath = results.prePath;

    await getBackgroundVideo();

    // if the command was the default generation command
    if (results.isDefault) {
      ArgResults args = results.args!;

      var removeCharacter = RemoveCharacters();

      // unnecessary until native tts is implemented
      //if (args['aws']) {
      //await pollyPutLexeme();
      //}

      String repeat = args['repeat'];

      if (validateLink(args['subreddit'])) {
        repeat = "1";
      }

      for (int i = 0; i < int.parse(repeat); i++) {
        // get all post data
        var (id, postData) = await getPostData(
          args['subreddit'], // subreddit
          args['sort'], // sort
          args['nsfw'], // nsfw tag
          int.parse(args['count']), // min number of comments
          args['comment-sort'], // sort for comments
          args['post-confirmation'], // check each post
          args['type'], // post type (e.g. comment or multi)
        );

        final bool alternateTTS = (args['alternate'][0] == 'on' ? true : false);
        final bool alternateColour =
            (args['alternate'][1] == 'on' ? true : false);
        final String titleColour = args['alternate'][2];

        final config =
            await File("$prePath/defaults/config.json").readAsString();
        final json = jsonDecode(config);
        final List<dynamic> voices =
            args['aws'] ? json['aws'] : json['accents'];
        final List<dynamic> colours = json['colours'];

        int currentTTS = 0;
        String voice = args['voice'];
        int currentColour = 0;

        Duration endTime = Duration.zero;

        // if the data collected returned nothing (e.g. subreddit has no posts)
        if (postData.isNotEmpty) {
          int counter = 0;
          String prevText = "";

          final newASS = File("$prePath/.temp/$id/comments.ass");
          final sinkComments = newASS.openWrite();
          final defaultASS =
              File("$prePath/defaults/default.ass").readAsStringSync();
          sinkComments.writeln(defaultASS);

          for (int i = 0; i < postData.length; i++) {
            for (int j = 0; j < postData[i].length; j++) {
              // if an aspect of the post doesn't contain any text
              // if ignored will produce weird noise in tts
              final post = postData[i];
              post[j] = removeCharacter.cleanse(post[j]);
              if (post[j].isNotEmpty) {
                List<String> textSegments = splitText(post[j]);
                for (String text in textSegments) {
                  if (text.isNotEmpty) {
                    bool ttsSuccess = await generateTTS(text, "$i-$counter",
                        args['ntts'], voice, args['censor'], id);
                    if (ttsSuccess) {
                      bool alignSuccess = await alignSubtitles(
                          "$i-$counter", prevText, args['verbose'], id);
                      if (!alignSuccess) {
                        exit(0);
                      } else {
                        endTime = await generateSubtitles(
                            id,
                            "$i-$counter",
                            alternateColour,
                            j == 0,
                            args['type'] != 'post',
                            (j == 0)
                                ? titleColour
                                : alternateColour
                                    ? colours[currentColour]
                                    : 'HFFFFFF',
                            endTime,
                            sinkComments);
                      }
                    } else {
                      exit(0);
                    }
                    counter++;
                    prevText = text;
                  }
                }
                if (alternateTTS) {
                  currentTTS = ++currentTTS % voices.length;
                  voice = voices[currentTTS];
                }
                if (alternateColour) {
                  currentColour = ++currentColour % colours.length;
                }
                endTime += Duration(
                    milliseconds: (args['type'] == 'comments' ? 1000 : 0));
              }
            }
            endTime +=
                Duration(milliseconds: (args['type'] == 'multi' ? 1000 : 0));
          }
          sinkComments.close();

          bool cutSuccess = await cutVideo(endTime, args['verbose'], id,
              endCardLength, args.wasParsed('end-card'));
          if (!cutSuccess) {
            exit(0);
          }

          List<String> command = generateCommand(args, endTime, i,
              args['horror'], id, endCardLength, args['type'] != 'post');
          bool ffmpegSuccess =
              await runFFMPEGCommand(command, args['output'], i);
          if (!ffmpegSuccess) {
            exit(0);
          }

          if (args['youtube-short']) {
            await splitVideo(args['output'], args['file-type'], i);
          }
          await writeToLog(id, args['type'] == 'multi');
          await clearTemp(id);
        } else {
          // output error
          printError("No post(s) found... Try again.");
        }
      }
      // if the command is flush
    } else if (results.command == Command.flush) {
      // remove data from visited_log.txt
      flushLog(results.args!['post']);
      await clearTemp();
    } else if (results.command == Command.install) {
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
      await installWhisper();
    }
  } on NoCommandException catch (e) {
    printError(
        '$e Try again but instead use a pre-existing command, for more information run reddit-2-video --help');
  } on Exception catch (e) {
    printError(e.toString());
  }
}
