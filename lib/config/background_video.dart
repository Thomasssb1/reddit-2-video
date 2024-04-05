import 'package:reddit_2_video/config/config_item.dart';
import 'package:reddit_2_video/exceptions/invalid_video_url_exception.dart';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:math';

enum VideoType { muxed, video }

class BackgroundVideo extends ConfigItem {
  final Uri url;
  final VideoType type;

  BackgroundVideo({
    required this.url,
    this.type = VideoType.video,
    super.path = "/defaults/video1.mp4",
  });

  bool _videoExists() {
    // store the last downloaded url and compare
    return path.existsSync();
  }

  Future<File> downloadVideo() async {
    bool exists = await _videoExists();
    if (!exists) {
      String? videoID = url.queryParameters['v'];
      if (videoID == null) {
        throw InvalidVideoUrl("Invalid video url", url);
      }
      YoutubeExplode yt = YoutubeExplode();
      late IOSink? fileStream;
      try {
        StreamManifest manifest = await yt.videos.streams.getManifest(videoID);
        late var streamInfo;
        switch (type) {
          case VideoType.muxed:
            streamInfo = manifest.muxed.sortByVideoQuality().first;
          case VideoType.video:
            streamInfo = manifest.videoOnly.sortByVideoQuality().first;
        }
        var stream = yt.videos.streamsClient.get(streamInfo);

        await path.create().then((File file) async {
          fileStream = file.openWrite();
          await stream.pipe(fileStream!).whenComplete(() => print(
              "\rBackground video successfully downloaded. You will not have to redownload the video again."));
        });
      } catch (e) {
        print("Error downloading video: $e");
        // throw the error
      } finally {
        yt.close();
        if (fileStream != null) {
          await fileStream!.flush();
          await fileStream!.close();
        }
        return path;
      }
    } else {
      return path;
    }
  }

  int _getRandomTime(int length) {
    final random = Random();
    int newTime(startTime, maxTime) => 0 + random.nextInt(maxTime);

    // temporarily store the video length as a fixed value
    int videoLength = Duration(seconds: 4813).inMilliseconds;

    int maxTime = videoLength - length;

    return newTime(0, maxTime);
  }

  void cutVideo() async {
    // cut the video
  }
}
