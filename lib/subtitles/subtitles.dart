import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/config/text_color.dart';
import 'package:reddit_2_video/config/voices.dart';
import 'package:reddit_2_video/exceptions/tts_failed_exception.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/subtitles/subtitle_config.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:reddit_2_video/subtitles/subtitle.dart';
import 'package:reddit_2_video/post/reddit_video_type.dart';
import 'package:reddit_2_video/post/reddit_post.dart';
import 'package:remove_emoji/remove_emoji.dart';
import 'package:reddit_2_video/config/voice.dart';

class Subtitles {
  late File _assFile;
  late Duration duration;
  final RedditVideo video;
  final bool ntts;
  final bool censor;
  final Duration delay;
  final Alternate alternate;
  int _position = 0;

  final List<Subtitle> _subtitles = <Subtitle>[];

  Subtitles({
    required this.video,
    required ParsedCommand command,
  })  : ntts = command.ntts,
        censor = command.censor,
        delay = command.type == RedditVideoType.post
            ? Duration.zero
            : Duration(seconds: 1),
        alternate = command.alternate {
    File defaultASS = File("${command.prePath}/defaults/default.ass");
    _assFile = defaultASS
        .copySync("${command.prePath}/.temp/${video.id}/comments.ass");
  }

  int get position => _position;
  set position(int newPosition) => _position = newPosition;

  String _removeCharacters(String text) {
    RemoveEmoji removeEmoji = RemoveEmoji();
    return removeEmoji.clean(text).replaceAll('&amp;#x200B;', '');
  }

  List<String> _splitText(String text) {
    RegExp punctuationMatch = RegExp(r"(\.|\?|!|\u2026)");
    int maxLength = 3000;

    List<String> newText = List.empty(growable: true);
    List<int> endPoints =
        punctuationMatch.allMatches(text).expand<int>((e) => [e.end]).toList();
    endPoints.insert(0, 0);
    int prevIndex = 0;
    for (int i = 0; i < endPoints.length; ++i) {
      if (endPoints[i] - endPoints[prevIndex] >= maxLength) {
        newText.add(text.substring(endPoints[prevIndex], endPoints[i - 1]));
        prevIndex = i - 1;
      } else if (i == endPoints.length - 1) {
        if (i != 0) {
          newText.add(text.substring(endPoints[prevIndex], endPoints[i]));
        }
        newText.add(text.substring(endPoints[i], text.length));
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
    final process = await Process.start(
        "aws",
        [
          "polly",
          "synthesize-speech",
          "--output-format",
          "mp3",
          "--voice-id",
          voice.id,
          "--text",
          text,
          "--engine",
          ntts ? "neural" : "standard",
          if (censor) "--lexicon-name=censor",
          ".temp/${video.id}/tts/tts-${_subtitles.length}.mp3",
        ],
        workingDirectory: command.prePath);
    if (command.verbose) {
      process.stderr.transform(utf8.decoder).listen((data) {
        stdout.write(data);
      });
      process.stdin.write(process.stdin);
    }
    int code = await process.exitCode;
    if (code != 0) {
      throw TTSFailedException(
          message: "TTS failed to generate. Exiting.",
          id: video.id,
          text: text);
    }
    return File(".temp/${video.id}/tts/tts-${_subtitles.length}.mp3");
  }

  Future<SubtitleConfig> _alignSubtitles(
      Subtitle prevSubtitle, ParsedCommand command, File tts) async {
    final process = await Process.start(
      "whisper_timestamped",
      [
        tts.absolute.path,
        "--language",
        "en",
        "--output_format",
        "json",
        "--compute_confidence",
        "False",
        if (prevSubtitle.text.isNotEmpty) ...[
          "--initial_prompt",
          prevSubtitle.text,
        ],
        "--output_dir",
        ".temp/${video.id}/config/",
      ],
      workingDirectory: command.prePath,
    );
    if (command.verbose) {
      process.stderr.transform(utf8.decoder).listen((data) {
        stdout.write(data);
      });
      process.stdin.write(process.stdin);
    }
    int code = await process.exitCode;
    if (code != 0) {
      throw TTSFailedException(
          message: "Aligning TTS to subtitles failed. Exiting.",
          id: video.id,
          text: prevSubtitle.text);
    }
    return SubtitleConfig.fromFile(
        tts: tts,
        configFile: File(
            "${command.prePath}/.temp/${video.id}/config/tts-${_subtitles.length}.mp3.words.json"));
  }

  Future<void> parse(ParsedCommand command) async {
    Voices.set(command.voice);
    Subtitle prevSubtitle = Subtitle.none();
    Duration prevDuration = Duration.zero;
    for (RedditPost post in video.posts) {
      String title = _removeCharacters(post.title);
      String body = _removeCharacters(post.body);

      List<String> comments = post.comments
          .map((e) => _removeCharacters(e.body))
          .where((e) => e.isNotEmpty)
          .toList();

      if (title.isNotEmpty) {
        (prevSubtitle, prevDuration) =
            await _parse(command, title, prevSubtitle, prevDuration, true);
      }

      if (body.isNotEmpty) {
        prevDuration += delay;
        (prevSubtitle, prevDuration) =
            await _parse(command, body, prevSubtitle, prevDuration, false);
      }

      if (comments.isNotEmpty) {
        for (String comment in comments) {
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
  }

  Future<(Subtitle, Duration)> _parse(ParsedCommand command, String text,
      Subtitle prevSubtitle, Duration prevDuration, bool isTitle) async {
    if (text.isNotEmpty) {
      List<String> segments = _splitText(text);
      for (String textSegment in segments) {
        if (textSegment.isNotEmpty) {
          Directory("${command.prePath}/.temp/${video.id}/tts/")
              .createSync(recursive: true);
          File tts = await _generateTTS(textSegment, Voices.current, command);

          Directory("${command.prePath}/.temp/${video.id}/config/")
              .createSync(recursive: true);
          SubtitleConfig config =
              await _alignSubtitles(prevSubtitle, command, tts);

          SubstationAlphaSubtitleColor color = TextColor.current;

          Subtitle subtitle = Subtitle(
              text: text, voice: command.voice, color: color, config: config);

          if (isTitle) {
            subtitle.updateTitleColours(alternate.titleColour);
          }

          await subtitle.generate(_assFile, prevDuration);

          _subtitles.add(subtitle);
          prevSubtitle = subtitle;
          prevDuration += subtitle.duration;
        }
      }
      if (alternate.tts) {
        Voices.next();
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
}
