import 'package:reddit_2_video/command/command_type.dart';
import 'package:args/args.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/config/voices.dart';
import 'dart:io';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/post/reddit_comment_sort_type.dart';
import 'package:reddit_2_video/post/reddit_post_sort_type.dart';
import 'package:reddit_2_video/post/reddit_url.dart';
import 'package:reddit_2_video/post/reddit_video_type.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:reddit_2_video/config/voice.dart';
import 'package:reddit_2_video/config/music.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
export 'package:reddit_2_video/command/command_type.dart';
import 'package:reddit_2_video/command/command.dart';
import 'package:reddit_2_video/utils/boolean_conversion.dart';

class ParsedCommand extends Command {
  final CommandType? _command;
  final ArgResults? _args;
  final Directory _prePath;

  ParsedCommand({
    required CommandType? command,
    required ArgResults args,
    ArgParser? parser,
  })  : _command = command,
        _args = args,
        _prePath = _determinePath(args),
        super(parser);

  ParsedCommand.defaultCommand({
    required ArgResults args,
    ArgParser? parser,
  })  : _command = CommandType.defaultCommand,
        _args = args,
        _prePath = _determinePath(args),
        super(parser);

  ParsedCommand.noArgs({
    required CommandType command,
    required ArgParser parser,
  })  : _command = command,
        _args = null,
        _prePath = Directory.current,
        super(parser);

  ParsedCommand.none()
      : _command = null,
        _args = null,
        _prePath = Directory.current,
        super(null);

  static ArgParser getParser() {
    ArgParser parser = ArgParser();
    // add parser options
    parser.addOption('subreddit', mandatory: true);
    parser.addOption('sort',
        defaultsTo: 'top', abbr: 's', allowed: ['hot', 'new', 'top', 'rising']);
    parser.addOption('comment-sort',
        defaultsTo: 'best',
        allowed: ['top', 'best', 'new', 'controversial', 'old', 'q&a']);
    parser.addOption('count',
        defaultsTo: '8', help: 'Maximum number of comments.');
    parser.addOption('type', defaultsTo: 'post', allowed: [
      'comments',
      'post',
      'multi'
    ], allowedHelp: {
      'comments':
          'Creates a video that contains a post title, body and a set number of comments for that post.',
      'post':
          'Creates a video that only contains a single post with the title and body.',
      'multi':
          'Creates a video that contains multiple posts from a single subreddit, not including comments.'
    });
    // TODO: Look into getting info from text such as female/male when assigning voices in future
    parser.addMultiOption('alternate',
        valueHelp: 'alternate-tts(on/off),alternate-colour(on/off)',
        help:
            'tts - alternate TTS voice for each comment/post (defaults to off)\ncolour - alternate text colour for each comment/post (defaults to off)',
        defaultsTo: ['off', 'off']);
    parser.addOption('title-color',
        valueHelp: 'the title colour for post in the format RRGGBB',
        defaultsTo: 'FF0000');
    parser.addFlag('post-confirmation', defaultsTo: false);
    parser
      ..addFlag('nsfw', defaultsTo: true)
      ..addFlag('spoiler',
          defaultsTo: false,
          help:
              'Add a spoiler to the video which hides the image/text before showing for 3s.');
    parser.addFlag('ntts',
        defaultsTo: true,
        help:
            'Determines whether to use neural tts or normal tts. (This will only affect usage if aws polly is active).');

    parser.addOption('voice',
        defaultsTo: 'Matthew', help: 'The voice to use for AWS Polly tts.');

    parser.addOption('repeat',
        help:
            'How many times the program should repeat - does not work for links but works for subreddits.',
        valueHelp: 'integer',
        defaultsTo: '1');
    parser.addOption('video',
        defaultsTo: 'defaults/video1.mp4',
        abbr: 'p',
        valueHelp: 'path-to-video');
    parser.addMultiOption('music', valueHelp: 'path,volume');
    parser.addFlag('youtube-short',
        help:
            'Whether or not to produce the final long form video with several videos split by a minute length as well as the full video.',
        defaultsTo: false);
    parser.addFlag('horror',
        help: 'Lowers the pitch from TTS for creepy stories.',
        defaultsTo: false);
    parser.addOption('output',
        abbr: 'o',
        defaultsTo: 'final',
        help: 'Location where the generated file will be stored.');
    parser.addOption('file-type',
        defaultsTo: 'mp4', allowed: ['mp4', 'avi', 'mov', 'flv']);
    parser.addOption('framerate',
        defaultsTo: '45',
        allowed: ['15', '30', '45', '60', '75', '120', '144'],
        help:
            'The framerate used when generating the video - using a higher framerate will take longer and produce a larger file.');
    parser.addFlag('censor',
        defaultsTo: false,
        help:
            'Censors any innapropriate words. This will only work when using AWS and you need to upload the defaults/lexicons/lexeme.xml file as a lexicon in AWS console.');
    parser.addOption('end-card',
        help: 'Path to a gif & audio that will play at the end of the video.',
        valueHelp: 'path-to-gif');
    parser
      ..addFlag('verbose', abbr: 'v', defaultsTo: false)
      ..addFlag('override', abbr: 'y', defaultsTo: false)
      ..addFlag('dev', abbr: 'd', hide: true, defaultsTo: false);
    parser.addFlag('help', abbr: 'h', hide: true);

    // create a new command
    var flush = parser.addCommand('flush');
    // add a command specific option
    flush.addOption('post',
        abbr: 'p', help: 'Remove a specific reddit post from the visited log.');
    flush.addFlag('dev', abbr: 'd', hide: true, defaultsTo: false);

    var install = parser.addCommand('install');
    install.addFlag('dev', abbr: 'd', hide: true, defaultsTo: false);
    return parser;
  }

  factory ParsedCommand.parse(List<String> args) {
    // init parser
    ArgParser parser = ParsedCommand.getParser();

    // parse the cli for arguments
    // throws an ArgParserException if the arguments are invalid
    var results = parser.parse(args);

    // if the command was the default generation command
    if (results.command == null) {
      // if the cli contained help argument
      if (results.wasParsed('help')) {
        // output the help message
        return ParsedCommand.noArgs(command: CommandType.help, parser: parser);
        // if the cli did not contain a subreddit/link
      } else if (!results.wasParsed('subreddit')) {
        throw ArgumentMissingException(
            'Argument <subreddit> is required. \nUse -help to get more information about usage.');
      } else if (results['alternate'].length != 2) {
        throw ArgumentMissingException(
            'The option --alternate needs 2 options each split by a comma. Check --help to see the syntax.');
      } else if (int.tryParse(results['repeat']) == null) {
        throw FormatException(
            'The value provided for --repeat must be an integer.');
      } else {
        // Non-terminating errors
        if (results.wasParsed('count') &&
            RedditUrl.validLink(results['subreddit'])) {
          Warning.warn(
              'The option --count does not work with a link, generation will continue but the --count option will be omitted.');
        }
        if (results.wasParsed('spoiler')) {
          Warning.warn(
              'Currently, --spoiler is not implemented, generation will continue as normal.');
        }
      }
      // return map of command and args
      return ParsedCommand.defaultCommand(args: results);
      // if the command is flush
    } else if (results.command!.name == 'flush') {
      return ParsedCommand(
          command: CommandType.flush,
          args: parser.commands['flush']!.parse(args));
      // if the command is install
    } else if (results.command!.name == 'install') {
      return ParsedCommand(
          command: CommandType.install,
          args: parser.commands['install']!.parse(args));
    }
    throw NoCommandException(
        'There is no such command ${results.command?.name}');
  }

  CommandType? get name => _command;
  ArgResults? get args => _args;
  String get prePath => _prePath.path;

  // individual argument getters and setters
  String get subreddit => _args!['subreddit'];
  RedditPostSortType get sort => RedditPostSortType.called(args!['sort'])!;
  RedditCommentSortType get commentSort =>
      RedditCommentSortType.called(args!['comment-sort'])!;
  int get commentCount => int.parse(args!['count']);
  RedditVideoType get type => RedditVideoType.called(args!['type'])!;
  Alternate get alternate => Alternate(
        tts: BooleanConversion(args!['alternate'][0]).parseBool(),
        color: BooleanConversion(args!['alternate'][1]).parseBool(),
      );
  SubstationAlphaSubtitleColor get titleColor =>
      SubstationAlphaSubtitleColor(args!['title-color']);
  bool get postConfirmation => args!['post-confirmation'];
  bool get nsfw => args!['nsfw'];
  bool get spoiler => args!['spoiler'];
  bool get ntts => args!['ntts'];
  Voice get voice => Voices.called(args!['voice']);
  int get repeat => subredditIsLink ? 1 : int.parse(args!['repeat']);
  // need to figure out what to do with video
  String get videoPath => args!['video'];
  Music? get music => args!['music'].length > 0
      ? Music(
          path: args!['music'][0],
          prePath: prePath,
          volume: args!['music'].length == 2 ? args!['music'][1] : "1.0",
        )
      : null;
  bool get youtubeShort => args!['youtube-short'];
  bool get horror => args!['horror'];
  String get output => args!['output'];
  FileType get fileType => FileType.called(args!['file-type'])!;
  FPS get framerate => FPS.fpsValue(int.parse(args!['framerate']));
  bool get censor => args!['censor'];
  EndCard? get endCard => args!['end-card'] != null
      ? EndCard(
          path: args!['end-card'],
          prePath: prePath,
        )
      : null;
  bool get verbose => args!['verbose'];
  bool get override => args!['override'];

  String? get post => args!['post'];

  T getArg<T>(String key) => _args![key] as T;

  bool get isDefault => _command == CommandType.defaultCommand;
  bool get isDev => _args?['dev'] ?? false;
  bool get isHelp => _args?['help'] ?? false;
  bool get subredditIsLink =>
      Uri.tryParse(_args!['subreddit'])?.hasAbsolutePath ?? false;

  static Directory _determinePath(ArgResults args) {
    return args['dev']
        ? Directory.current
        : File(Platform.resolvedExecutable).parent.parent;
  }
}
