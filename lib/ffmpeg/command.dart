import 'package:args/args.dart';
import 'package:reddit_2_video/utils/prepath.dart';
import 'package:path/path.dart' as p;
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/tts/get.dart';

List<String> generateCommand(
    ArgResults args, Duration endTime, int count, bool horrorMode, String id, int endCardLength) {
  String output = args['output'];
  String fileType = args['file-type'];
  List<String> music = args['music'];
  String fps = args['framerate'];
  String subtitlePath = prePath[0] +
      r"\" +
      prePath.substring(1, prePath.length).replaceAll(r'\', r'\\') +
      r"\\.temp\\" +
      id +
      r"\\comments.ass";

  // if the output provided is a directory
  if (output.endsWith('/')) {
    print("No filename provided - using a default filename.");
    // creates new filename called final
    output += "final";
  } // if the output provided is a file
  else {
    // get the filename and file-extension from the output path provided
    String fileName = p.basename(output);
    String fileExtension = fileName.split(RegExp(r'^.*(?=(\.[0-9a-z]+$))')).last.replaceFirst('.', '');
    // remove the file extension from the output path
    output = output.replaceAll(".$fileExtension", '');
    // if the file-extension from the output path provided
    // is not the same as the file-type argument provided
    if (fileExtension != fileType && fileExtension.isNotEmpty) {
      printWarning(
          "\nOutput file extension does not match the requested filetype, overriding the filetype to be the same as the value of the --file-type option ($fileType).\n If you do not want this to happen, then change the value of the --file-type flag to match the desired output type.\n");
    }
  }

  List<String> ttsFiles = getTTSFiles(id);
  List<String> inputStreams =
      List.generate(ttsFiles.length, (index) => "[${index + (args.wasParsed('end-card') ? 2 : 1)}:a]");

  List<String> command = [
    "-i", "$prePath/.temp/$id/video.mp4",
    if (args.wasParsed('end-card')) ...["-i", args['end-card']],
    ...List.generate(ttsFiles.length, (index) => ["-i", "$prePath/.temp/$id/tts/tts-$index.mp3"], growable: false)
        .expand((e) => e)
        .toList(),
    if (args['music'].isNotEmpty) ...["-i", args['music'][0]],
    if (args['override']) '-y',
    if (!args['verbose']) ...['-loglevel', 'quiet'],
    '-map',
    '[final_a]',
    '-filter_complex',
    // *
    """${inputStreams.join(' ')} concat=n=${ttsFiles.length}:v=0:a=1${horrorMode ? ',rubberband=pitch=0.8' : ''}${(music.isNotEmpty) ? '[0a];[${ttsFiles.length + (args.wasParsed('end-card') ? 2 : 1)}:a]volume=${double.tryParse(music[1]) ?? 1}[1a];[0a][1a]amerge' : ''}[final_a];${args.wasParsed('end-card') ? "[1:v]setpts=PTS-STARTPTS+${endTime.inSeconds + 1}/TB[gif];[0:v][gif]overlay=((main_w/2)-(overlay_w/2)):((main_h/2)-(overlay_h/2)):enable='between(t,${endTime.inSeconds + 1}, ${endTime.inSeconds + endCardLength + 1})'," : "[0:v]"}crop=585:1080, subtitles='$subtitlePath', fps=$fps""",
    '$output${(count == 0) ? "" : count}.$fileType'
  ];
  return command;
}
