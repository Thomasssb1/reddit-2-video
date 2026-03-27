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

class EndCard extends ConfigItem {
  final Duration duration;
  int? position;

  EndCard._({
    required File path,
    required this.duration,
    this.position,
  }) : super(path: path.path, prePath: '', fileFactory: (_, __) => path);

  /// Creates an [EndCard] and resolves its duration.
  ///
  /// If the file is a gif/video, duration is probed from the file via ffprobe.
  /// If an explicit [durationOverride] is supplied AND the file duration could
  /// be inferred, a warning is logged (the override is still respected).
  /// For static images the [durationOverride] is required; a default of 5 s is
  /// used if it is not provided.
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

    Duration resolved;

    if (isImage) {
      // Static image — use override or fall back to 5 s default.
      resolved = durationOverride ?? const Duration(seconds: 5);
    } else {
      // gif / video — try to infer from the file.
      final probed = await _probeFileDuration(file);
      if (durationOverride != null && probed != null) {
        Warning.warn(
            '--end-card-length is overriding the inferred end-card duration '
            '(${probed.inSeconds}s) with ${durationOverride.inSeconds}s. '
            'Remove --end-card-length to use the file duration automatically.');
        resolved = durationOverride;
      } else if (durationOverride != null) {
        // ffprobe not available or file had no duration; honour override silently.
        resolved = durationOverride;
      } else if (probed != null) {
        resolved = probed;
      } else {
        // Fallback: ffprobe failed and no override given for a gif/video.
        Warning.warn(
            'Could not infer end-card duration from file. '
            'Falling back to 5 s. Use --end-card-length to set an explicit value.');
        resolved = const Duration(seconds: 5);
      }
    }

    return EndCard._(path: file, duration: resolved);
  }
}
