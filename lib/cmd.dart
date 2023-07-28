import 'dart:io';
import 'package:args/args.dart';
import 'package:reddit_2_video/utils.dart';

/// parse the command line arguments entered.
dynamic parse(args) {
  // init parser
  var parser = ArgParser();
  // add parser options
  parser.addOption('subreddit');
  parser.addOption('sort', defaultsTo: 'hot', abbr: "s", allowed: ['hot', 'new', 'top', 'rising']);
  parser.addOption('comment-sort', defaultsTo: 'top', allowed: ['top', 'best', 'new', 'controversial', 'old', 'q&a']);
  parser.addOption('count', defaultsTo: '8', help: 'Minimum number of comments.');
  parser.addOption('type', defaultsTo: 'comments', allowed: [
    'comments',
    'post',
    'multi'
  ], allowedHelp: {
    'comments': 'Creates a video that contains a post title, body and a set number of comments for that post.',
    'post': 'Creates a video that only contains a single post with the title and body.',
    'multi': 'Creates a video that contains multiple posts from a single subreddit, not including comments.'
  });
  // Look into getting info such as female/male when assigning voices in future
  parser.addMultiOption('alternate',
      valueHelp: "alternate-tts(on/off),alternate-colour(on/off),title-colour(hex)",
      help:
          "tts - alternate TTS voice for each comment/post (defaults to off)\ncolour - alternate text colour for each comment/post (defaults to off)\ntitle-colour - determine title colour for post (defaults to #FF0000).");
  parser.addFlag('post-confirmation', defaultsTo: false);
  parser
    ..addFlag('nsfw', defaultsTo: true)
    ..addFlag('spoiler',
        defaultsTo: false, help: 'Add a spoiler to the video which hides the image/text before showing for 3s.');
  parser.addFlag('ntts',
      defaultsTo: true,
      help:
          'Determines whether to use neural tts which is generated locally or googles own TTS which requires internet.');
  parser.addOption(
    'accent',
    defaultsTo: 'com.mx',
    allowed: ['com.mx', 'co.uk', 'com.au', 'us', 'ca', 'co.in', 'ie', 'co.za'],
    help: 'The accent to be used when not using ntts.\nUse a top-level-domain from google such as com.mx or co.uk',
  );
  parser.addOption('video-path', defaultsTo: 'defaults/video1.mp4', abbr: 'v', valueHelp: "path");
  parser.addMultiOption('music', valueHelp: "path,volume");
  parser.addOption('output', abbr: 'o', defaultsTo: 'final', help: 'Location where the generated file will be stored.');
  parser.addOption('file-type', defaultsTo: 'mp4', allowed: ['mp4', 'avi', 'mov', 'flv']);
  parser.addOption('framerate',
      defaultsTo: '45',
      allowed: ['15', '30', '45', '60', '75', '120', '144'],
      help:
          'The framerate used when generating the video - using a higher framerate will take longer and produce a larger file.');
  parser.addFlag('verbose', defaultsTo: false);
  parser.addFlag('override', defaultsTo: false);
  parser.addFlag('help', hide: true);

  // create a new command
  var flush = parser.addCommand('flush');
  // add a command specific option
  flush.addOption('post', abbr: 'p', help: 'Remove a specific reddit post from the visited log.');

  // parse the cli for arguments
  var results = parser.parse(args);

  // if the command was the default generation command
  if (results.command == null) {
    // if the cli contained help argument
    if (results.wasParsed('help')) {
      // output the help message
      printHelp(parser.usage);
      exit(1);
      // if the cli did not contain a subreddit/link
    } else if (!results.wasParsed('subreddit')) {
      stderr.writeln('Argument <subreddit> is required. \nUse -help to get more information about usage.');
      exit(1);
      // if the user entered an accent while ntts is active (does not affect)
    } else if (results['ntts'] && results.wasParsed('accent')) {
      printWarning(
          'The option --accent will not be used as ntts is active. For accent to be used, ntts needs to be set to false.');
    }
    // return map of command and args
    return {'command': null, 'args': results};
    // if the command is flush
  } else {
    return {'command': 'flush', 'args': flush.parse(args)};
  }
}
