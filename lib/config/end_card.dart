import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:reddit_2_video/config/config_item.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';

/// File extensions considered "static images" (duration cannot be inferred).
const _imageExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif'};

/// Probe a video/gif file and return its duration via ffprobe.
/// Returns `null` if ffprobe is unavailable or the file has no duration.
Future<Duration?> _probeFileDuration(File file) async {
  try {
    final result = await Process.run('ffprobe', [
      '-v', 'error',
      '-show_entries', 'format=duration',
      '-of', 'json',
      file.path,
    ]);
    if (result.exitCode != 0) return null;

    final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final raw = (json['format'] as Map<String, dynamic>)['duration'];
    if (raw == null) return null;

    final seconds = double.tryParse(raw.toString());
    if (seconds == null) return null;

    return Duration(milliseconds: (seconds * 1000).round());
  } catch (_) {
    return null;
  }
}

Future<Duration> _resolveDuration(File file, Duration? override, bool isImage) async {
  if (isImage) {
    if (override == null) {
      throw ArgumentMissingException(
          'Static images require an explicit duration. Use --end-card-length.');
    }
    return override;
  }

  final probed = await _probeFileDuration(file);

  if (override != null && probed != null) {
    Warning.warn(
        '--end-card-length is overriding the inferred end-card duration '
        '(${probed.inSeconds}s) with ${override.inSeconds}s. '
        'Remove --end-card-length to use the file duration automatically.');
  } else if (override == null && probed == null) {
    Warning.warn(
        'Could not infer end-card duration from file. '
        'Falling back to 5s. Use --end-card-length to set an explicit value.');
  }

  return override ?? probed ?? const Duration(seconds: 5);
}

class EndCard extends ConfigItem {
  final Duration duration;
  int? position;

  EndCard._({
    required File path,
    required this.duration,
  }) : super.fromFile(path);

  /// Creates an [EndCard] and resolves its duration.
  ///
  /// If the file is a gif/video, duration is probed from the file via ffprobe.
  /// If an explicit [durationOverride] is supplied AND the file duration could
  /// be inferred, a warning is logged (the override is still respected).
  /// For static images the [durationOverride] is required
  static Future<EndCard> create({
    required String path,
    required String prePath,
    Duration? durationOverride,
    File Function(String, String)? fileFactory,
  }) async {
    final file =
        (fileFactory ?? ConfigItem.getPathStatic)(path.replaceFirst('/', ''), prePath);

    final ext = p.extension(file.path).toLowerCase();
    final isImage = _imageExtensions.contains(ext) && ext != '.gif';

    final resolved = await _resolveDuration(file, durationOverride, isImage);

    return EndCard._(path: file, duration: resolved);
  }
}
