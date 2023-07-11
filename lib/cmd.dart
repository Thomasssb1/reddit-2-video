import 'dart:io';

import 'package:args/args.dart';
import 'package:reddit_2_video/utils.dart';

ArgResults? parse(args) {
  var parser = ArgParser();
  parser.addOption('subreddit');
  parser.addOption('sort', defaultsTo: 'hot', abbr: "s", allowed: ['hot', 'new', 'top', 'rising']);
  parser.addOption('comment-sort', defaultsTo: 'top', allowed: ['top', 'best', 'new', 'controversial', 'old', 'q&a']);
  parser.addOption('count', defaultsTo: '8', help: 'Minimum number of comments');
  parser.addOption('type', defaultsTo: 'comments', allowed: ['comments', 'post', 'multi']);
  // Look into getting info such as female/male when assigning voices in future
  parser.addMultiOption('alternate',
      valueHelp: "alternate-tts(true/false),alternate-colour(true/false),title-colour(hex)");
  parser.addFlag('post-confirmation', defaultsTo: false);
  parser
    ..addFlag('nsfw', defaultsTo: true)
    ..addFlag('spoiler',
        defaultsTo: false, help: 'Add a spoiler to the video which hides the image/text before showing for 3s');
  parser.addFlag('ntts',
      defaultsTo: false,
      help:
          'Determines whether to use neural tts which is generated locally or googles own TTS which requires internet.');
  parser
    ..addFlag('upvotes', defaultsTo: false, abbr: 'u', help: 'Display upvotes on overlay')
    ..addFlag('downvotes', defaultsTo: false, abbr: 'd', help: 'Display downvotes on overlay')
    ..addFlag('awards', defaultsTo: false, abbr: 'a', help: 'Display awards on overlay');
  parser.addOption('video-path', defaultsTo: '../defaults/video1.mp4', abbr: 'v', valueHelp: "path");
  parser.addMultiOption('music', valueHelp: "path,volume");
  parser.addFlag('date', defaultsTo: false, help: 'Add date of when the post was uploaded to the overlay.');
  parser.addOption('timezone',
      abbr: 't',
      defaultsTo: 'GMT',
      hide: true,
      help: 'Timezone to use when adding date to the post overlay',
      allowed: ['GMT', 'ECT', 'EET', 'PST', 'CST', 'EST']);
  parser.addOption('output', abbr: 'o', defaultsTo: 'final', help: 'Location where the generated file will be stored.');
  parser.addOption('file-type', defaultsTo: 'mp4', allowed: ['mp4', 'avi', 'mov', 'flv']);
  parser.addOption('framerate',
      defaultsTo: '45',
      allowed: ['15', '30', '45', '60', '75', '120', '144'],
      help:
          'The framerate used when generating the video - using a higher framerate will take longer and produce a larger file.');
  parser.addFlag('verbose', defaultsTo: false);
  parser.addOption('help', abbr: 'h', help: 'Provide information on how to use reddit-2-video');

  var results = parser.parse(args);

  if (results.wasParsed('help')) {
    printHelp(parser.usage);
    //printSuccess(parser.usage);
    return null;
  } else if (!results.wasParsed('subreddit')) {
    stderr.writeln('Argument <subreddit> is required. \nUse -help to get more information about usage.');
    return null;
  }

  return parser.parse(args);
}
