import 'dart:io';

import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/config/music.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:path/path.dart' as p;
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';

class FFmpegCommand {
  final Subtitles subtitles;
  final BackgroundVideo backgroundVideo;
  final EmptyNoise? emptyNoise;
  final Music? music;
  final EndCard? endCard;

  const FFmpegCommand({
    required this.subtitles,
    required this.backgroundVideo,
    this.emptyNoise,
    this.music,
    this.endCard,
  });

  List<String> inputFiles(File cutVideo) {
    List<String> inputs = [
      "-i",
      cutVideo.path,
    ];
    int currentPosition = backgroundVideo.position + 1;
    if (emptyNoise != null) {
      emptyNoise!.position = currentPosition;
      currentPosition++;
      inputs.addAll(["-i", emptyNoise!.path.path]);
    }
    if (music != null) {
      music!.position = currentPosition;
      currentPosition++;
      inputs.addAll(["-i", music!.path.path]);
    }
    if (endCard != null) {
      endCard!.position = currentPosition;
      currentPosition++;
      inputs.addAll(["-i", endCard!.path.path]);
    }
    inputs.addAll(subtitles.getTTSFilesAsInput());
    subtitles.position = currentPosition;
    return inputs;
  }

  List<String> _getFlags(ParsedCommand command) {
    return [
      "-nostdin",
      if (command.override) "-y" else "-n",
      if (!command.verbose) ...["-loglevel", "quiet"],
    ];
  }

  List<String> get audioStream => subtitles.getTTSStream(emptyNoise);

  String _concat() {
    return "${audioStream.join(' ')} concat=n=${audioStream.length}:v=0:a=1";
  }

  String _horrorMode(bool horrorMode) {
    return horrorMode ? ',rubberband=pitch=0.8' : '';
  }

  String _addMusic() {
    if (music?.position == null) return '';
    return "[0a];[${music!.position!}:a]volume=${music!.volume}[1a];[0a][1a]amerge";
  }

  String _addEndCard() {
    if (endCard?.position == null) return "[0:v]";
    int showAt = subtitles.duration.inSeconds + 1;
    int endcardLength = endCard!.duration.inSeconds;
    return "[${endCard!.position!}:v]setpts=PTS-STARTPTS+$showAt/TB[gif];[0:v][gif]overlay=((main_w/2)-(overlay_w/2)):((main_h/2)-(overlay_h/2)):enable='between(t,$showAt, ${showAt + endcardLength + 1})',";
  }

  String _cropVideo() {
    return "crop=585:1080";
  }

  String _escapeFilterPath(String path) {
    return path
        .replaceAll(r'\', '/')
        .replaceAll(':', r'\:')
        .replaceAll("'", r"\'");
  }

  String _addSubtitles() {
    return "subtitles='${_escapeFilterPath(subtitles.assFile.path)}'";
  }

  String _addFps(FPS fps) {
    return ",fps=${fps.value}";
  }

  String _getFilter(ParsedCommand command) {
    return """${_concat()}${_horrorMode(command.horror)}${_addMusic()}[final_a];${_addEndCard()}${_cropVideo()},${_addSubtitles()}${_addFps(command.framerate)}[final_v]""";
  }

  String _getOutput(ParsedCommand command, int index) {
    String output = command.output;
    FileType fileType = command.fileType;

    String fileExtension = p.extension(output);
    if (fileExtension.isEmpty) {
      Warning.warn("No filename provided - using a default filename.");
      output = "final";
    } else {
      if (FileType.called(fileExtension.substring(1)) != fileType) {
        Warning.warn(
            "File extension of output does not match requested the --file-type option. Using the value of the --file-type option.");
      }
      output = p.withoutExtension(output);
    }
    String count = command.repeat == 1 ? "" : "-$index";
    return "$output$count.${fileType.name}";
    // need to handle youtube short naming
  }

  List<String> generate(ParsedCommand command, File cutVideo, int index) {
    /// Generate the command to be executed
    return [
      ...inputFiles(cutVideo),
      ..._getFlags(command),
      "-map",
      "[final_a]",
      "-map",
      "[final_v]",
      "-filter_complex",
      _getFilter(command),
      _getOutput(command, index)
    ];
  }
}
