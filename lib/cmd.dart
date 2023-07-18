import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:reddit_2_video/log.dart';
import 'package:reddit_2_video/utils.dart';

dynamic parse(args) {
  var parser = ArgParser();
  parser.addOption('subreddit');
  parser.addOption('sort', defaultsTo: 'hot', abbr: "s", allowed: ['hot', 'new', 'top', 'rising']);
  parser.addOption('comment-sort', defaultsTo: 'top', allowed: ['top', 'best', 'new', 'controversial', 'old', 'q&a']);
  parser.addOption('count', defaultsTo: '8', help: 'Minimum number of comments');
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
          "tts - alternate TTS voice for each comment/post (defaults to off)\ncolour - alternate text colour for each comment/post (defaults to off)\ntitle-colour - determine title colour for post (defaults to #FF0000)");
  parser.addFlag('post-confirmation', defaultsTo: false);
  parser
    ..addFlag('nsfw', defaultsTo: true)
    ..addFlag('spoiler',
        defaultsTo: false, help: 'Add a spoiler to the video which hides the image/text before showing for 3s');
  parser.addFlag('ntts',
      defaultsTo: true,
      help:
          'Determines whether to use neural tts which is generated locally or googles own TTS which requires internet.');
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
  parser.addFlag('help');

  var flush = parser.addCommand('flush');
  flush.addOption('post', abbr: 'p', help: 'Remove a specific reddit post from the visited log.');

  var results = parser.parse(args);

  if (results.command == null) {
    if (results.wasParsed('help')) {
      printHelp(parser.usage);
      exit(1);
    } else if (!results.wasParsed('subreddit')) {
      stderr.writeln('Argument <subreddit> is required. \nUse -help to get more information about usage.');
      exit(1);
    }
  } else {
    return {'command': 'flush', 'args': flush.parse(args)};
  }

  return {'command': null, 'args': results};
}
