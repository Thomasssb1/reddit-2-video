import 'package:reddit_2_video/exceptions/background_video_cutting_exception.dart';
import 'package:reddit_2_video/exceptions/invalid_video_url_exception.dart';
import 'package:reddit_2_video/exceptions/video_download_failed_exception.dart';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:math';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/reddit_video.dart';

enum VideoType { muxed, video }

class BackgroundVideo {
  final Uri url;
  final VideoType type;
  File path;
  int position = 0;

  BackgroundVideo({
    required this.url,
    required String prePath,
    this.type = VideoType.video,
    String path = "/defaults/video1.mp4",
  }) : path = File("$prePath$path");

  bool _videoExists() {
    // store the last downloaded url and compare
    return path.existsSync();
  }

  Future<File> downloadVideo() async {
    bool exists = _videoExists();
    if (!exists) {
      String? videoID = url.queryParameters['v'];
      if (videoID == null) {
        throw InvalidVideoUrl("Invalid video url", url);
      }
      YoutubeExplode yt = YoutubeExplode();
      late IOSink? fileStream;
      try {
        StreamManifest manifest = await yt.videos.streams.getManifest(videoID);
        late List<VideoStreamInfo> streamInfo;
        switch (type) {
          case VideoType.muxed:
            streamInfo = manifest.muxed.sortByVideoQuality();
          case VideoType.video:
            streamInfo = manifest.videoOnly.sortByVideoQuality();
        }

        VideoStreamInfo chosenStream =
            streamInfo.where((e) => e.container == StreamContainer.mp4).first;
        var stream = yt.videos.streamsClient.get(chosenStream);

        await path.create().then((File file) async {
          fileStream = file.openWrite();
          await stream.pipe(fileStream!).whenComplete(() => print(
              "\rBackground video successfully downloaded. You will not have to redownload the video again."));
        });

        await fileStream!.flush();
        await fileStream!.close();
      } on StateError {
        throw VideoDownloadFailedException(
            message: "No mp4 streams available. Unable to download video.",
            url: url);
      } catch (e) {
        throw VideoDownloadFailedException(
            message: "Error downloading video", url: url);
      } finally {
        yt.close();
      }
      return path;
    } else {
      return path;
    }
  }

  (int, int) _getRandomTime(Duration duration) {
    final random = Random();
    int newTime(startTime, maxTime) => 0 + random.nextInt(maxTime);

    // temporarily store the video length as a fixed value
    int videoLength = Duration(seconds: 4813).inMilliseconds;

    int maxTime = videoLength - duration.inMilliseconds;

    int start = newTime(0, maxTime);

    return (start, start + duration.inMilliseconds);
  }

  Future<void> cutVideo(
      Duration duration, RedditVideo video, ParsedCommand command) async {
    stdout.write("Cutting the background video to a random point.");
    Duration endCardLength = command.endCard?.duration ?? Duration.zero;
    var (startTime, endTime) =
        _getRandomTime(duration + endCardLength + Duration(milliseconds: 1500));

    final process = await Process.start(
        'ffmpeg',
        [
          '-ss',
          '${startTime}ms',
          '-to',
          '${endTime}ms',
          '-y',
          '-nostdin',
          '-i',
          path.path,
          '-c:v',
          'copy',
          '-c:a',
          'copy',
          if (!command.verbose) ...['-loglevel', 'quiet'],
          '.temp/${video.id}/video.mp4'
        ],
        workingDirectory: command.prePath);
    int code = await process.exitCode;
    if (code != 0) {
      throw BackgroundVideoCuttingException(
          message:
              "Something went wrong when trying to cut the background video.",
          url: url,
          duration: duration);
    } else {
      path = File(".temp/${video.id}/video.mp4");
    }
  }
}
