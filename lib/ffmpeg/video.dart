import 'dart:io';
import 'dart:math';
import 'package:reddit_2_video/utils/globals.dart' show prePath;
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';
import 'package:reddit_2_video/subtitles/time.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

String getVideoId(String video) {
  try {
    var link = Uri.parse(video);
    return link.query.replaceFirst('v=', '');
  } catch (e) {
    // check if valid id in future
    print(
        "Continuing with video generation, assuming the value you put for --video is the id.");
    return video;
  }
}

getBackgroundVideo() async {
  // change to allow video input then make name the same as vid/id
  bool videoExists = await File("$prePath/defaults/video1.mp4").exists();
  if (!videoExists) {
    String videoID = getVideoId("https://www.youtube.com/watch?v=n_Dv4JMiwK8");
    print(
        "\rDownloading background video from youtube. The video being downloaded is https://www.youtube.com/watch?v=$videoID. This is a one time process and will not need to be dowloaded again.");
    var yt = YoutubeExplode();
    var manifest = await yt.videos.streams.getManifest(videoID);
    late var streamInfo;
    streamInfo = manifest.videoOnly.sortByVideoQuality().first;
    var stream = yt.videos.streamsClient.get(streamInfo);
    await File("$prePath/defaults/video1.mp4").create().then((File file) async {
      var fileStream = file.openWrite();

      await stream.pipe(fileStream).whenComplete(() => print(
          "\rBackground video successfully downloaded. You will not have to redownload the video again."));
      await fileStream.flush();
      await fileStream.close();
    });
    yt.close();
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

Future<bool> cutVideo(Duration endTime, bool verbose, String id,
    int endCardLength, bool hasEndCard) async {
  print("Cutting the background video to a random point.");
  int startTime = getRandomTime(endTime.inMilliseconds +
      1500 +
      (hasEndCard ? (endCardLength * 1000) : 0));
  int code = await runCommand(
      'ffmpeg',
      [
        '-ss',
        '${startTime}ms',
        '-to',
        '${startTime + endTime.inMilliseconds + 1500 + (hasEndCard ? (endCardLength * 1000) : 0)}ms',
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
      workingDirectory: prePath);
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
