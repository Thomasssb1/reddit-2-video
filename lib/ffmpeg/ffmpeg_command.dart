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

  List<String> get inputFiles {
    List<String> inputs = [
      "-i",
      backgroundVideo.path.path,
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
      if (command.override) "-y",
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
    return "[${music!.position!}:a]volume=${music!.volume}[1a];[0a][1a]amerge";
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

  String _addSubtitles() {
    return "subtitles='${subtitles.assFile.path}'";
  }

  String _addFps(FPS fps) {
    return ",fps=${fps.value}";
  }

  String _getFilter(ParsedCommand command) {
    return """${_concat()}${_horrorMode(command.horror)}${_addMusic()}[final_a];${_addEndCard()}${_cropVideo()},${_addSubtitles()}${_addFps(command.framerate)}""";
  }

  String _getOutput(ParsedCommand command) {
    String output = command.output;
    FileType fileType = command.fileType;

    String fileExtension = p.extension(output);
    if (fileExtension.isEmpty) {
      Warning.warn("No filename provided - using a default filename.");
      output += "final";
    } else {
      if (FileType.called(fileExtension.substring(1)) != fileType) {
        Warning.warn(
            "File extension of output does not match requested the --file-type option. Defaulting to the value of the --file-type option.");
        fileType = FileType.called(fileExtension.substring(1))!;
      }
      output = p.withoutExtension(output);
    }
    return "$output.${fileType.name}";
    // need to handle youtube short naming
  }

  List<String> generate(ParsedCommand command) {
    /// Generate the command to be executed
    return [
      ...inputFiles,
      ..._getFlags(command),
      "-map",
      "[final_a]",
      "-filter_complex",
      _getFilter(command),
      _getOutput(command)
    ];
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("FFmpeg inputs: ");
    sb.write(inputFiles.join(" "));
    return sb.toString();
  }
}
