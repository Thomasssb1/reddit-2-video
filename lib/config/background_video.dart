import 'package:reddit_2_video/exceptions/background_video_cutting_exception.dart';
import 'package:reddit_2_video/exceptions/invalid_video_url_exception.dart';
import 'package:reddit_2_video/exceptions/video_download_failed_exception.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'dart:io';
import 'dart:math';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/subprocess.dart';

enum VideoType { muxed, video }

class BackgroundVideo {
  File source;
  Uri? url;
  int position = 0;

  BackgroundVideo({
    required String path,
    this.url,
  }) : source = AppPaths.resolve(path);

  BackgroundVideo.fromFile({
    required this.source,
    this.url,
  });

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
        _validVideoId(url.pathSegments.first));
  }

  static bool _validDefaultUrl(Uri url) {
    Uri defaultValid = Uri.https("www.youtube.com", "watch", {"v": "0"});
    return (url.authority == defaultValid.authority &&
        url.path == defaultValid.path &&
        url.queryParameters.containsKey("v") &&
        _validVideoId(url.queryParameters["v"]!));
  }

  static bool _validVideoId(String id) =>
      RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id);

  static bool _validYoutubeUrl(Uri url) {
    // First check default uri validity, then share validity
    return _validDefaultUrl(url) || _validShareUrl(url);
  }

  static Future<BackgroundVideo> downloadVideo(Uri url,
      {VideoType videoType = VideoType.video, bool verbose = false}) async {
    if (!_validYoutubeUrl(url)) {
      throw InvalidVideoUrl("Invalid youtube url", url);
    }

    url = normalizeYoutubeUri(url);
    File path = _getFileFromUrl(url);

    // Download the video if not already downloaded
    if (!_videoExists(url)) {
      path.parent.createSync(recursive: true);
      final format = _ytDlpFormatSelector(videoType);
      final args = [
        '--no-playlist',
        '--no-part',
        '-f',
        format,
        '-o',
        path.path,
        url.toString(),
      ];

      try {
        final result = await Subprocess.exec(
          'yt-dlp',
          args,
          verbose: verbose,
          section: LogSection.backgroundVideo,
        );
        if (result.exitCode != 0) {
          final stderrOutput = result.stderr.trim();
          final details = stderrOutput.isNotEmpty ? ' $stderrOutput' : '';
          throw VideoDownloadFailedException(
              message:
                  "yt-dlp failed with exit code ${result.exitCode}.$details",
              url: url);
        }
      } on ProcessException catch (e) {
        throw VideoDownloadFailedException(message: e.message, url: url);
      } catch (e) {
        throw VideoDownloadFailedException(
            message: "Error downloading video: $e", url: url);
      }

      if (!path.existsSync()) {
        throw VideoDownloadFailedException(
            message: "yt-dlp finished but no output file was created.",
            url: url);
      }
    }
    return BackgroundVideo.fromFile(source: path, url: url);
  }

  static String _ytDlpFormatSelector(VideoType videoType) =>
      videoType == VideoType.video
          ? 'bestvideo[ext=mp4]/best[ext=mp4]'
          : 'best[ext=mp4]/best';

  (double, double) _getRandomTime(Duration duration) {
    final random = Random();

    double videoLengthSec = 4813.0;
    double durationSec = duration.inMilliseconds / 1000.0;
    double maxTimeSec = videoLengthSec - durationSec;

    if (maxTimeSec < 0) maxTimeSec = 0;
    double startSec = random.nextDouble() * maxTimeSec;

    return (startSec, startSec + durationSec);
  }

  Future<File> cutVideo(
      Duration duration, RedditVideo video, ParsedCommand command) async {
    logger.info(
      "Cutting the background video to a random point.",
      section: LogSection.backgroundVideo,
    );
    Duration endCardLength = (await command.endCard)?.duration ?? Duration.zero;
    var (startTime, endTime) =
        _getRandomTime(duration + endCardLength + Duration(milliseconds: 1500));

    final ffmpegCommand = [
      '-ss',
      startTime.toStringAsFixed(3),
      '-y',
      '-nostdin',
      '-i',
      source.path,
      '-t',
      (endTime - startTime).toStringAsFixed(3),
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-an',
      if (!command.verbose) ...['-loglevel', 'quiet'],
      '.temp/${video.id}/video.mp4'
    ];

    final result = await Subprocess.exec(
      'ffmpeg',
      ffmpegCommand,
      verbose: command.verbose,
      section: LogSection.backgroundVideo,
    );
    int code = result.exitCode;

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
