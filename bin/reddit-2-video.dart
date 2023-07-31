import 'package:reddit_2_video/log.dart';
import 'package:reddit_2_video/reddit_2_video.dart';
import 'package:reddit_2_video/utils.dart';
import 'package:reddit_2_video/cmd.dart';
import 'dart:io';
import 'package:reddit_2_video/ffmpeg.dart';

/// [enable preview ffplay]
/// [add styling to title and fade in etc using .ass]
//
void main(List<String> arguments) async {
  // delete .gitkeep so that it isn't counted when getting all tts files
  if (await File('./.temp/tts/.gitkeep').exists()) {
    await File('./.temp/tts/.gitkeep').delete().catchError((error) {
      printError(
          "Something went wrong when trying to delete a temporary file. To fix this you can go to the ./reddit-2-video/.temp/tts folder and delete the .gitkeep file. Error: $error");
      exit(1);
    });
  }

  // get the arguments passed on command line
  var results = parse(arguments);
  var args = results['args'];

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

    // if the data collected returned nothing (e.g. subreddit has no posts)
    if (postData.isNotEmpty) {
      // generate subtitles as well as tts
      int end_ms = await generateSubtitles(
        args['ntts'],
        postData,
        args['accent'],
        args['voice'],
        (args['alternate'][0] == 'on') ? true : false,
        (args['alternate'][1] == 'on') ? true : false,
        args['alternate'][2],
      );
      int ttsCount = await Directory('./.temp/tts').list().length;

      // create a ffmpeg command that can be run
      List<String> command = await generateCommand(
        args['output'],
        end_ms,
        args['framerate'],
        args['file-type'],
        args['music'],
        args['video-path'],
        args['override'],
        ttsCount,
        args['verbose'],
      );

      // run the ffmpeg command
      await generateVideo(
        command,
      );
    } else {
      // output error
      printError("No post(s) found... Try again.");
    }
    // if the command is flush
  } else if (results['command'] == 'flush') {
    // remove data from visited_log.txt
    flushLog(results['args']['post']);
  }
}
