import 'package:reddit_2_video/exceptions/background_video_cutting_exception.dart';
import 'package:reddit_2_video/exceptions/invalid_video_url_exception.dart';
import 'package:reddit_2_video/exceptions/video_download_failed_exception.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:math';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/reddit_video.dart';

enum VideoType { muxed, video }

class BackgroundVideo {
  File source;
  Uri? url;
  int position = 0;

  BackgroundVideo({required this.source, this.url});

  BackgroundVideo.fromPath({
    required String path,
    Uri? url,
  }) : this(source: File(path), url: url);

  static File _getFileFromUrl(Uri url) {
    String vId = url.queryParameters["v"]!;
    return AppPaths.resolve('defaults/$vId.mp4');
  }

  static bool _videoExists(Uri url) {
    File file = _getFileFromUrl(url);
    return file.existsSync();
  }

  static Uri normalizeYoutubeUri(Uri url) {
    if (!_validYoutubeUrl(url)) {
      throw InvalidVideoUrl("Invalid youtube url", url);
    }

    if (_validDefaultUrl(url)) {
      return url;
    }

    String vId = url.pathSegments.first;
    return Uri.https("www.youtube.com", "watch", {"v": vId});
  }

  static bool _validShareUrl(Uri url) {
    Uri shareValid = Uri.https("youtu.be", "0");
    return (url.authority == shareValid.authority &&
        VideoId.validateVideoId(url.pathSegments.first));
  }

  static bool _validDefaultUrl(Uri url) {
    Uri defaultValid = Uri.https("www.youtube.com", "watch", {"v": "0"});
    return (url.authority == defaultValid.authority &&
        url.path == defaultValid.path &&
        url.queryParameters.containsKey("v") &&
        VideoId.validateVideoId(url.queryParameters["v"]!));
  }

  static bool _validYoutubeUrl(Uri url) {
    // First check default uri validity, then share validity
    return _validDefaultUrl(url) || _validShareUrl(url);
  }

  static Future<BackgroundVideo> downloadVideo(Uri url,
      {VideoType videoType = VideoType.video}) async {
    if (!_validYoutubeUrl(url)) {
      throw InvalidVideoUrl("Invalid youtube url", url);
    }

    url = normalizeYoutubeUri(url);
    File path = _getFileFromUrl(url);

    if (!_videoExists(url)) {
      String? videoID = url.queryParameters['v'];
      if (videoID == null) {
        throw InvalidVideoUrl("Invalid video url", url);
      }
      YoutubeExplode yt = YoutubeExplode();
      late IOSink? fileStream;
      try {
        StreamManifest manifest = await yt.videos.streams.getManifest(videoID);
        final VideoStreamInfo chosenStream =
            _selectMp4Stream(manifest, preferredType: videoType);
        var stream = yt.videos.streamsClient.get(chosenStream);

        await path.create().then((File file) async {
          fileStream = file.openWrite();
          await stream.pipe(fileStream!).whenComplete(() => print(
              "\rBackground video successfully downloaded. You will not have to redownload the video again."));
        });

        await fileStream!.flush();
        await fileStream!.close();
      } on StateError catch (e) {
        throw VideoDownloadFailedException(message: e.message, url: url);
      } catch (e) {
        throw VideoDownloadFailedException(
            message: "Error downloading video: $e", url: url);
      } finally {
        yt.close();
      }
      return BackgroundVideo(source: path, url: url);
    } else {
      return BackgroundVideo(source: path, url: url);
    }
  }

  static VideoStreamInfo _selectMp4Stream(StreamManifest manifest,
      {required VideoType preferredType}) {
    final preferred = preferredType == VideoType.video
        ? manifest.videoOnly.sortByVideoQuality()
        : manifest.muxed.sortByVideoQuality();
    final secondary = preferredType == VideoType.video
        ? manifest.muxed.sortByVideoQuality()
        : manifest.videoOnly.sortByVideoQuality();

    for (final stream in preferred) {
      if (stream.container == StreamContainer.mp4) {
        return stream;
      }
    }

    for (final stream in secondary) {
      if (stream.container == StreamContainer.mp4) {
        return stream;
      }
    }

    throw StateError("No mp4 streams available. Unable to download video.");
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

  Future<File> cutVideo(
      Duration duration, RedditVideo video, ParsedCommand command) async {
    stdout.writeln("Cutting the background video to a random point.");
    Duration endCardLength = (await command.endCard)?.duration ?? Duration.zero;
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
          source.path,
          '-c:v',
          'copy',
          '-an',
          if (!command.verbose) ...['-loglevel', 'quiet'],
          '.temp/${video.id}/video.mp4'
        ],
        workingDirectory: AppPaths.rootPath);
    int code = await process.exitCode;

    if (code != 0) {
      throw BackgroundVideoCuttingException(
          message:
              "Something went wrong when trying to cut the background video.",
          url: url?.toString() ?? "None",
          duration: duration);
    } else {
      return File(".temp/${video.id}/video.mp4");
    }
  }

  static Uri getDefaultVideoUrl() =>
      Uri.parse("https://www.youtube.com/watch?v=n_Dv4JMiwK8");
}
