import 'dart:convert';
import 'dart:io';
import 'utils.dart';
import 'package:path/path.dart' as p;

/// Write subtitles to .ass file with [custom animation] and [colours]
///
/// Create new tts along with each comment
Future<int> generateSubtitles(
  bool nttsActive,
  List<dynamic> postData,
  String accent,
  String voice,
  bool alternateTTS,
  bool alternateColour,
  String titleColour,
) async {
  bool installed = await checkInstall('python');
  if (!installed) {
    printError(
        "Python is not installed. You need python in order to continue.\nLearn more here: \x1b[0mhttps://github.com/Thomasssb1/reddit-2-video");
    exit(0);
  }

  /// [Remember] ffmpeg uses `HBBGGRR`
  String animation(colour) =>
      r"{\an5\1c&H000000&\t(0, 150, \1c&" +
      colour +
      r"& \frz0\frscx0\frscy0\t(0, 150, \fscx100, \fscy100))}{\fad(150,150)}";

  // read the config file
  // for list of voices/accents and colours
  final config = File("./defaults/config.json");
  final json = jsonDecode(config.readAsStringSync());
  final List<dynamic> voicesAccents = nttsActive ? json['voices'] : json['accents'];
  final List<dynamic> colours = json['colours'];

  // read the default subtitles file
  final defaultASS = File("./defaults/default.ass");
  final contents = await defaultASS.readAsString();

  // open the new temporary subtitles file
  final fileForComments = File("./.temp/comments.ass");
  final sinkComments = fileForComments.openWrite();
  // write the default subtitles files contents to temporary
  sinkComments.write("$contents\n");

  // initialise start time and tts counter
  String startTime = "0:00:00.00";
  int counter = 1;
  int currentTTS = voicesAccents.indexOf(nttsActive ? voice : accent);
  int currentColour = 0;
  String ttsMessage = 'Generating TTS ...';
  // iterate through each post (2d)
  // [
  //  [title, body text, comments]
  // ]
  print(
      "Starting the process of generating TTS. This generally takes longer as it is also generating the subtitles to go along with it. ~4m");
  final stream = Stream<String>.periodic(const Duration(seconds: 1), (secondCount) {
    return "${secondCount + 1}s";
  });
  var msg = stream.listen((text) {
    stdout.write("\r$ttsMessage $text");
  });
  //stream.forEach((text) {
  //stdout.write("\r$ttsMessage $text");
  //});
  for (final post in postData) {
    for (int i = 0; i < post.length; i++) {
      // if an aspect of the post doesn't contain any text
      // if ignored will produce weird noise in tts
      if (post[i].isNotEmpty) {
        // split the comments so that it can be displayed on screen properly
        final List<String> splitInfo = splitComments(post[i].replaceAll("\n", " "));
        // iterate through the split text

        for (final text in splitInfo) {
          // generate the tts and get the duration of the file
          final duration = await generateTTS(text, counter, nttsActive, voicesAccents[currentTTS]);
          ttsMessage = "\x1b[32mTTS successfully generated. $counter ...\x1b[0m";
          // calculate the new time based off the previous time and the duration
          final newTime = lengthCalculation(duration, startTime);
          // if the text is the title
          if (i == 0) {
            // use red colour for title
            sinkComments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,${animation(titleColour)}$text\n");
          } else {
            if (alternateColour) {
              sinkComments
                  .write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,${animation(colours[currentColour])}$text\n");
            } else {
              sinkComments.write("Dialogue: 0,$startTime,$newTime,Default,,0,0,0,,${animation('HFFFFFF')}$text\n");
            }
          }
          // update variables
          startTime = newTime;
          counter++;
        }
        if (alternateTTS) {
          currentTTS = ++currentTTS % voicesAccents.length;
        }
        if (alternateColour) {
          currentColour = ++currentColour % colours.length;
        }
      }
    }
  }
  msg.cancel();
  // close and save the file
  sinkComments.close();

  // return the total time in milliseconds
  int prevMinutes = int.parse(startTime[2] + startTime[3]);
  int prevSeconds = int.parse(startTime[5] + startTime[6]);
  int prevMilliseconds = int.parse(startTime.substring(8)) * 10;

  // is used to trim the video length
  return (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000));
}

/// Create a command that can be run in the cli using [ffmpeg]
Future<List<String>> generateCommand(
  String output,
  int end,
  String fps,
  String fileType,
  List<String> music,
  String video,
  bool override,
  int ttsCount,
  bool verbose,
) async {
  // add the video as the first input
  List<String> command = ["-i", video];

  // add each of the tts files to the command
  command.addAll(List.generate(ttsCount, (index) => ["-i", "./.temp/tts/tts-$index.wav"], growable: false)
      .expand((e) => e)
      .toList());

  // add each tts input stream as an audio stream (does not include video stream)
  List<String> inputStreams = List.generate(ttsCount, (index) => "[${index + 1}:a]");

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
    if (fileExtension != fileType) {
      printWarning(
          "\nOutput file extension does not match the requested filetype, overriding the filetype to be the same as the value of the --file-type option ($fileType).\n If you do not want this to happen, then change the value of the --file-type flag to match the desired output type.\n");
    }
  }

  // create a list of each argument required for ffmpeg
  command.addAll([
    // if the music argument is added then add that as an input stream
    if (music.isNotEmpty) ...[
      '-i',
      music[0],
    ],
    // if the override flag is passed
    if (override) '-y',
    if (!verbose) ...[
      '-loglevel',
      'quiet',
    ],

    // map the singular video stream
    '-map',
    '0:v',
    // map each audio input into a single audio output
    '-map',
    '[final_a]',
    // trim video between 0s and end time calculated
    '-ss',
    '0ms',
    '-to',
    '${end + 100}ms',
    '-filter_complex',
    // *
    '${inputStreams.join(' ')} concat=n=$ttsCount:v=0:a=1${(music.isNotEmpty) ? "[0a];[${ttsCount + 1}:a]volume=${double.tryParse(music[1]) ?? 1}[1a];[0a][1a]amerge" : ""}[final_a], crop=585:1080, subtitles=.temp/comments.ass, fps=$fps',
    '$output.$fileType'
  ]);

  // *: Add each audio stream to the start so that they can be added to the concatenation filter
  // if the music arg is passed then create a new map output 0a which feeds into a volume filter
  // and merges the audio streams into one
  // otherwise ignore the steps previous
  // crop the video size to be better fit for tiktok/phone screens
  // pass the subtitles filter as well as the fps filter if the arg was passed (default is used otherwise)

  return command;
}
