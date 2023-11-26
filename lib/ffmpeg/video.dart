import 'dart:io';
import 'dart:math';
import 'package:reddit_2_video/utils/prepath.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';
import 'package:reddit_2_video/subtitles/time.dart';

getBackgroundVideo() async {
  bool videoExists = await File("$prePath\\defaults\\video1.mp4").exists();
  if (!videoExists) {
    runCommand("ytdl/ytdl.exe", ["-v", "https://www.youtube.com/watch?v=n_Dv4JMiwK8", "-o", "defaults/video1.mp4"],
        false, prePath);
  }
}

int getRandomTime(int length) {
  final random = Random();
  int newTime(startTime, maxTime) => 0 + random.nextInt(maxTime);

  // temporarily store the video length as a fixed value
  int videoLength = Duration(seconds: 4813).inMilliseconds;

  int maxTime = videoLength - length;

  return newTime(0, maxTime);
}

Future<bool> cutVideo(Duration endTime, bool verbose, String id, int endCardLength) async {
  print("Cutting the background video to a random point.");
  int startTime = getRandomTime(endTime.inMilliseconds + 1500 + endCardLength);
  int code = await runCommand(
      'ffmpeg',
      [
        '-ss',
        '${startTime}ms',
        '-to',
        '${startTime + endTime.inMilliseconds + 1500 + (endCardLength * 1000)}ms',
        '-y',
        '-nostdin',
        '-i',
        'defaults/video1.mp4',
        '-c:v',
        'copy',
        '-c:a',
        'copy',
        if (!verbose) ...['-loglevel', 'quiet'],
        '.temp/$id/video.mp4'
      ],
      true,
      prePath);
  if (code == 0) {
    printSuccess(
        "Video has been cut between times ${getNewTime(Duration(milliseconds: startTime))} and ${getNewTime(Duration(milliseconds: startTime + endTime.inMilliseconds + 1500 + (endCardLength * 1000)))}.");
    return true;
  } else {
    printError(
        "Something went wrong when trying to cut the background video. Please try again. If the problem persists then post this as an issue on the github page.\nhttps://github.com/Thomasssb1/reddit-2-video/issues");
    return false;
  }
}
