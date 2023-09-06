import 'dart:io';
import 'dart:math';
import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';
import 'package:reddit_2_video/subtitles/time.dart';

getBackgroundVideo() async {
  bool videoExists = await File("$prePath\\defaults\\video1.mp4").exists();
  if (!videoExists) {
    runCommand(
        "ytdl/ytdl.exe",
        [
          "-v",
          "https://www.youtube.com/watch?v=n_Dv4JMiwK8",
          "-o",
          "defaults/video1.mp4"
        ],
        false,
        prePath);
  }
}

int getRandomTime(int length) {
  final random = new Random();
  int newTime(startTime, maxTime) => 0 + random.nextInt(maxTime);

  // temporarily store the video length as a fixed value
  int videoLength = Duration(seconds: 4813).inMilliseconds;

  int maxTime = videoLength - length;

  return newTime(0, maxTime);
}

Future<bool> cutVideo(Duration endTime, bool verbose) async {
  print(
      "Cutting the video to a random point. This can take a while depending on the video size. Please wait.");
  int startTime = getRandomTime(endTime.inMilliseconds + 100);
  int code = await runCommand(
      'ffmpeg',
      [
        '-ss',
        '${startTime}ms',
        '-to',
        '${startTime + endTime.inMilliseconds + 100}ms',
        '-y',
        '-nostdin',
        '-i',
        'defaults/video1.mp4',
        if (!verbose) ...['-loglevel', 'quiet'],
        '.temp/video.mp4'
      ],
      true,
      prePath);
  if (code == 0) {
    printSuccess(
        "Video has been cut between times ${getNewTime(Duration(milliseconds: startTime))} and ${getNewTime(Duration(milliseconds: startTime + endTime.inMilliseconds + 100))}.");
    return true;
  } else {
    printError(
        "Something went wrong when trying to cut the background video. Please try again. If the problem persists then post this as an issue on the github page.\nhttps://github.com/Thomasssb1/reddit-2-video/issues");
    return false;
  }
}
