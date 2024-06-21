import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/text_color.dart';
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
  final RedditVideo video;
  final bool ntts;
  final bool censor;
  final Duration delay;
  final Alternate alternate;

  List<Subtitle> _subtitles = <Subtitle>[];

  Subtitles({
    required this.video,
    required ParsedCommand command,
  })  : ntts = command.ntts,
        censor = command.censor,
        delay = command.type == RedditVideoType.post
            ? Duration.zero
            : Duration(seconds: 1),
        alternate = command.alternate {
    File defaultASS = File("defaults/default.ass");
    _assFile = defaultASS.copySync(".temp/${video.id}/comments.ass");
  }

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
        tts.path,
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
        "/.temp/${video.id}/config",
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

  void parse(ParsedCommand command) async {
    Voice.set(command.voice);
    Subtitle prevSubtitle = Subtitle.none();
    Duration prevDuration = Duration.zero;
    for (RedditPost post in video.posts) {
      String title = _removeCharacters(post.title);
      String body = _removeCharacters(post.body);
      List<String> comments =
          post.comments.map((e) => _removeCharacters(e.body)).toList();

      if (title.isNotEmpty) {
        (prevSubtitle, prevDuration) =
            await _parse(command, title, prevSubtitle, prevDuration, true);
      }
      if (body.isNotEmpty) {
        (prevSubtitle, prevDuration) =
            await _parse(command, body, prevSubtitle, prevDuration, false);
      }
      if (comments.isNotEmpty) {
        for (String comment in comments) {
          (prevSubtitle, prevDuration) =
              await _parse(command, comment, prevSubtitle, prevDuration, false);
        }
      }
      if (command.type == RedditVideoType.multi) {
        prevDuration += delay;
      }
    }
  }

  Future<(Subtitle, Duration)> _parse(ParsedCommand command, String text,
      Subtitle prevSubtitle, Duration prevDuration, bool isTitle) async {
    if (text.isNotEmpty) {
      List<String> segments = _splitText(text);
      for (String textSegment in segments) {
        if (textSegment.isNotEmpty) {
          File tts = await _generateTTS(textSegment, Voice.current, command);
          SubtitleConfig config =
              await _alignSubtitles(prevSubtitle, command, tts);

          SubstationAlphaSubtitleColor color =
              isTitle ? alternate.titleColour : TextColor.current;

          Subtitle subtitle = Subtitle(
              text: text, voice: command.voice, color: color, config: config);

          subtitle.generate(_assFile, prevDuration);

          _subtitles.add(subtitle);
          prevSubtitle = subtitle;
        }
      }
      if (alternate.tts) {
        Voice.next();
      }
      if (alternate.color) {
        TextColor.next();
      }
      prevDuration += delay;
    }
    return (prevSubtitle, prevDuration);
  }
}
