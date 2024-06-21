import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/exceptions/tts_failed_exception.dart';
import 'package:reddit_2_video/subtitles/alternate.dart';
import 'package:reddit_2_video/subtitles/subtitle_config.dart';
import 'package:reddit_2_video/utils/substation_alpha_subtitle_color.dart';
import 'package:reddit_2_video/subtitles/subtitle.dart';
import 'package:reddit_2_video/post/reddit_post.dart';
import 'package:reddit_2_video/config/voice.dart';
import 'package:remove_emoji/remove_emoji.dart';

class Subtitles {
  bool ntts;
  bool censor;
  Duration delay;
  late File _assFile;
  late Duration length;
  late Alternate alternate;

  List<Subtitle> _subtitles = <Subtitle>[];

  Subtitles({
    required RedditPost post,
    required Alternate alternate,
    this.delay = Duration.zero,
    this.ntts = true,
    this.censor = false,
  }) {
    File defaultASS = File("defaults/default.ass");
    _assFile = defaultASS.copySync(".temp/${post.id}/comments.ass");
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
      String text, ParsedCommand command, RedditPost post) async {
    final process = await Process.start(
        "aws",
        [
          "polly",
          "synthesize-speech",
          "--output-format",
          "mp3",
          "--voice-id",
          command.voice.id,
          "--text",
          text,
          "--engine",
          ntts ? "neural" : "standard",
          if (censor) "--lexicon-name=censor",
          ".temp/${post.id}/tts/tts-${_subtitles.length}.mp3",
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
          message: "TTS failed to generate. Exiting.", id: post.id, text: text);
    }
    return File(".temp/${post.id}/tts/tts-${_subtitles.length}.mp3");
  }

  Future<SubtitleConfig> _alignSubtitles(Subtitle prevSubtitle,
      ParsedCommand command, RedditPost post, File tts) async {
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
        "/.temp/${post.id}/config",
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
          id: post.id,
          text: prevSubtitle.text);
    }
    return SubtitleConfig.fromFile(
        tts: tts,
        configFile: File(
            "${command.prePath}/.temp/${post.id}/config/tts-${post.id}.mp3.words.json"));
  }

  void parse(RedditPost post, ParsedCommand command) async {
    String title = _removeCharacters(post.title);
    String body = _removeCharacters(post.body);
    // comments also need to be done here
    Subtitle prevSubtitle = Subtitle.none();
    prevSubtitle = await _parse(post, command, title, prevSubtitle, true);
    prevSubtitle = await _parse(post, command, body, prevSubtitle, false);
  }

  Future<Subtitle> _parse(RedditPost post, ParsedCommand command, String text,
      Subtitle prevSubtitle, bool isTitle) async {
    if (text.isNotEmpty) {
      List<String> segments = _splitText(text);
      for (String textSegment in segments) {
        if (textSegment.isNotEmpty) {
          File tts = await _generateTTS(textSegment, command, post);
          SubtitleConfig config =
              await _alignSubtitles(prevSubtitle, command, post, tts);

          SubstationAlphaSubtitleColor color = isTitle
              ? alternate.titleColour
              : SubstationAlphaSubtitleColor("#FFFFFF");

          Subtitle subtitle = Subtitle(
              text: text, voice: command.voice, color: color, config: config);

          subtitle.generate(_assFile, prevSubtitle);

          _subtitles.add(subtitle);
          prevSubtitle = subtitle;
        }
      }
    }
    return prevSubtitle;
  }
}
