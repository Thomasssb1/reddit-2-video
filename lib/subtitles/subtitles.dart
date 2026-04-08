import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/config/text_color.dart';
import 'package:reddit_2_video/config/voices/voices.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/subtitles/subtitle_config.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:reddit_2_video/subtitles/subtitle.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/utils/string_utils.dart';
import 'package:reddit_2_video/config/voices/voice.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/progress.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';

class Subtitles {
  late File _assFile;
  late Duration duration;
  final RedditVideo video;
  final bool ntts;
  final bool censor;
  final Duration delay;
  final Alternate alternate;
  final SubstationAlphaSubtitleColor titleColor;
  final List<Lexica> lexicons;
  final Voices voices;
  int position = 0;

  final List<Subtitle> _subtitles = <Subtitle>[];
  String? _progressTask;
  int _plannedSegments = 0;

  Subtitles({
    required this.video,
    required this.lexicons,
    required this.voices,
    required ParsedCommand command,
  })  : ntts = command.ntts,
        censor = command.censor,
        delay = command.type == RedditVideoType.post
            ? Duration.zero
            : command.delay,
        alternate = command.alternate,
        titleColor = command.titleColor {
    File defaultASS = AppPaths.resolve('defaults/default.ass');
    File assDestination = AppPaths.resolve('.temp/${video.id}/comments.ass');
    _assFile = defaultASS.copySync(assDestination.path);
  }

  List<String> _splitText(String text) {
    RegExp punctuationMatch = RegExp(r"(\.|\?|!|\u2026)");
    int maxLength = 3000;

    List<String> newText = <String>[];
    List<int> endPoints =
        punctuationMatch.allMatches(text).expand<int>((e) => [e.end]).toList();
    endPoints.insert(0, 0);
    endPoints.add(text.length);
    int prevIndex = 0;
    for (int i = 0; i < endPoints.length; ++i) {
      if (endPoints[i] - endPoints[prevIndex] > maxLength) {
        newText.add(text.substring(endPoints[prevIndex], endPoints[i - 1]));
        prevIndex = i - 1;
      } else if (i == endPoints.length - 1) {
        newText.add(text.substring(endPoints[prevIndex], text.length));
      }
    }
    List<String> tempText = [];
    RegExp splitMatch = RegExp('.{1,$maxLength}');
    for (final line in newText) {
      if (line.length > maxLength) {
        tempText.addAll(splitMatch.allMatches(line).map((e) => e[0]!).toList());
      } else {
        tempText.add(line);
      }
    }
    return tempText;
  }

  Future<File> _generateTTS(
      String text, Voice voice, ParsedCommand command) async {
    final arguments = _pollyArguments(
      text: text,
      voice: voice,
      outputFormat: "mp3",
      outputPath: ".temp/${video.id}/tts/tts-${_subtitles.length}.mp3",
    );
    final result = await Subprocess.exec(
      "aws",
      arguments,
      verbose: command.verbose,
      section: LogSection.subtitles,
    );

    if (result.exitCode != 0) {
      throw TTSFailedException(
        message: "TTS failed to generate. Exit code: ${result.exitCode}.",
        id: video.id,
        text: text,
        executable: 'aws',
        arguments: arguments,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
      );
    }
    if (_progressTask != null) {
      generationProgress.incrementTask(_progressTask!,
          detail: 'Generated TTS ${_subtitles.length + 1}/$_plannedSegments');
    }
    return File(".temp/${video.id}/tts/tts-${_subtitles.length}.mp3");
  }

  Future<SubtitleConfig> _alignSubtitles(
      String text, Voice voice, ParsedCommand command, File tts) async {
    final arguments = _pollyArguments(
      text: text,
      voice: voice,
      outputFormat: "json",
      outputPath:
          ".temp/${video.id}/config/tts-${_subtitles.length}.mp3.words.json",
      speechMarkTypes: const ["word"],
    );
    final result = await Subprocess.exec(
      "aws",
      arguments,
      verbose: command.verbose,
      section: LogSection.subtitles,
    );

    if (result.exitCode != 0) {
      throw TTSFailedException(
        message:
            "Speech marks failed to generate. Exit code: ${result.exitCode}.",
        id: video.id,
        text: text,
        executable: 'aws',
        arguments: arguments,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
      );
    }

    if (_progressTask != null) {
      generationProgress.incrementTask(_progressTask!,
          detail:
              'Aligned subtitles ${_subtitles.length + 1}/$_plannedSegments');
    }
    return SubtitleConfig.fromFile(
        tts: tts,
        configFile: AppPaths.resolve(
            '.temp/${video.id}/config/tts-${_subtitles.length}.mp3.words.json'));
  }

  List<String> _pollyArguments({
    required String text,
    required Voice voice,
    required String outputFormat,
    required String outputPath,
    List<String> speechMarkTypes = const [],
  }) {
    return [
      "polly",
      "synthesize-speech",
      if (censor) ...<String>[
        "--lexicon-names",
        ...lexicons.map((e) => e.toString()),
      ],
      "--output-format",
      outputFormat,
      "--voice-id",
      voice.id,
      "--text",
      text,
      "--engine",
      ntts ? "neural" : "standard",
      if (speechMarkTypes.isNotEmpty) ...<String>[
        "--speech-mark-types",
        jsonEncode(speechMarkTypes),
      ],
      outputPath,
    ];
  }

  Future<void> parse(ParsedCommand command) async {
    _plannedSegments = _countSegments();
    _progressTask = generationProgress.createTask(
      title: 'Preparing subtitles',
      detail: '0/$_plannedSegments segments for ${video.id}',
      section: LogSection.subtitles,
      totalUnits: math.max(1, _plannedSegments * 3).toDouble(),
      weight: math.max(6, _plannedSegments * 3).toDouble(),
    );
    Subtitle prevSubtitle = Subtitle.none();
    Duration prevDuration = Duration.zero;
    final maxLength = command.maxLength;

    for (RedditPost post in video.posts) {
      // --- multi type: check before starting a new post ---
      if (command.type == RedditVideoType.multi && maxLength != null) {
        if (prevDuration >= maxLength && _subtitles.isNotEmpty) {
          logger.warning(
              'Max length of ${maxLength}s reached '
              '(${prevDuration.inSeconds}s accumulated). '
              'Stopping before next post.',
              section: LogSection.subtitles);
          break;
        }
      }

      String title = post.title.cleanse();
      String body = post.body.cleanse();

      List<String> comments = post.comments
          .map((e) => e.body.cleanse())
          .where((e) => e.isNotEmpty)
          .toList();

      // The comments type will abort if title alone would exceed max length
      // We cannot know if the title will exceed without generating TTS first
      if (title.isNotEmpty) {
        (prevSubtitle, prevDuration) =
            await _parse(command, title, prevSubtitle, prevDuration, true);

        // After generating the title, check if we're already over for comments type.
        if (command.type == RedditVideoType.comments &&
            maxLength != null &&
            prevDuration >= maxLength) {
          throw MaxLengthExceededException(
              message:
                  'Max length of ${maxLength}s exceeded by the post title alone '
                  '(${prevDuration.inSeconds}s). Generation aborted.',
              maxLength: maxLength,
              actualLength: prevDuration);
        }
      }

      if (body.isNotEmpty) {
        prevDuration += delay;
        (prevSubtitle, prevDuration) =
            await _parse(command, body, prevSubtitle, prevDuration, false);
      }

      if (comments.isNotEmpty) {
        for (String comment in comments) {
          // Stop adding comments once max length reached.
          if (command.type != RedditVideoType.post &&
              maxLength != null &&
              prevDuration >= maxLength) {
            logger.warning(
                'Max length of ${maxLength}s reached '
                '(${prevDuration.inSeconds}s accumulated). '
                'Stopping before next comment.',
                section: LogSection.subtitles);
            break;
          }
          prevDuration += delay;
          (prevSubtitle, prevDuration) =
              await _parse(command, comment, prevSubtitle, prevDuration, false);
        }
      }
      if (command.type == RedditVideoType.multi) {
        prevDuration += delay;
      }
    }
    duration = prevDuration;
    if (_progressTask != null) {
      generationProgress.completeTask(_progressTask!,
          detail: 'Prepared $_plannedSegments subtitle segments');
    }
  }

  Future<(Subtitle, Duration)> _parse(ParsedCommand command, String text,
      Subtitle prevSubtitle, Duration prevDuration, bool isTitle) async {
    if (text.isNotEmpty) {
      List<String> segments = _splitText(text);
      for (String textSegment in segments) {
        if (textSegment.isNotEmpty) {
          AppPaths.resolveDir('.temp/${video.id}/tts')
              .createSync(recursive: true);
          File tts = await _generateTTS(textSegment, voices.current, command);

          AppPaths.resolveDir('.temp/${video.id}/config')
              .createSync(recursive: true);
          SubtitleConfig config =
              await _alignSubtitles(textSegment, voices.current, command, tts);

          SubstationAlphaSubtitleColor color = TextColor.current;

          Subtitle subtitle =
              Subtitle(text: text, color: color, config: config);

          if (isTitle) {
            subtitle.updateTitleColours(titleColor);
          }

          await subtitle.generate(_assFile, prevDuration);
          if (_progressTask != null) {
            generationProgress.incrementTask(_progressTask!,
                detail:
                    'Wrote subtitles ${_subtitles.length + 1}/$_plannedSegments');
          }

          _subtitles.add(subtitle);
          prevSubtitle = subtitle;
          prevDuration += subtitle.duration;
        }
      }
      if (alternate.tts) {
        voices.next();
      }
      if (alternate.color) {
        TextColor.next();
      }
    }
    return (prevSubtitle, prevDuration);
  }

  List<String> getTTSFilesAsInput() {
    List<String> files = [];
    for (Subtitle subtitle in _subtitles) {
      files.addAll(["-i", subtitle.config.tts.absolute.path]);
    }
    return files;
  }

  List<String> getTTSStream(EmptyNoise? emptyNoise) {
    List<String> stream = [];
    bool hasDelay = emptyNoise?.position != null;
    for (int i = 0; i < _subtitles.length; ++i) {
      stream.addAll([
        "[${i + position}:a]",
        if (hasDelay && i < _subtitles.length - 1) "[${emptyNoise!.position}:a]"
      ]);
    }
    return stream;
  }

  File get assFile => _assFile;

  int _countSegments() {
    int countSegmentsInText(String text) {
      if (text.isEmpty) return 0;
      return _splitText(text).where((segment) => segment.isNotEmpty).length;
    }

    var count = 0;
    for (final post in video.posts) {
      count += countSegmentsInText(post.title.cleanse());
      count += countSegmentsInText(post.body.cleanse());
      for (final comment in post.comments) {
        count += countSegmentsInText(comment.body.cleanse());
      }
    }
    return count;
  }
}
