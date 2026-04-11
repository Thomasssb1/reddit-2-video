enum SubprocessProgressMode { none, ffmpeg, ytDlp }

class SubprocessProgressUpdate {
  final double? fraction;
  final String detail;

  const SubprocessProgressUpdate({
    this.fraction,
    required this.detail,
  });
}

abstract class SubprocessProgressParser {
  bool handleLine(
    String line,
    void Function(SubprocessProgressUpdate update)? onProgress,
  );
}

SubprocessProgressParser? createSubprocessProgressParser(
  SubprocessProgressMode mode, {
  Duration? expectedDuration,
}) {
  switch (mode) {
    case SubprocessProgressMode.ffmpeg:
      return FfmpegProgressParser(expectedDuration: expectedDuration);
    case SubprocessProgressMode.ytDlp:
      return YtDlpProgressParser();
    case SubprocessProgressMode.none:
      return null;
  }
}

class FfmpegProgressParser implements SubprocessProgressParser {
  final Duration? expectedDuration;
  final Map<String, String> _currentFrame = {};

  FfmpegProgressParser({this.expectedDuration});

  @override
  bool handleLine(
    String line,
    void Function(SubprocessProgressUpdate update)? onProgress,
  ) {
    final separatorIndex = line.indexOf('=');
    if (separatorIndex == -1) {
      return false;
    }

    final key = line.substring(0, separatorIndex);
    final value = line.substring(separatorIndex + 1);
    _currentFrame[key] = value;

    if (key != 'progress') {
      return true;
    }

    final outTimeMs = int.tryParse(_currentFrame['out_time_ms'] ?? '');
    final speed = _currentFrame['speed'];
    final fps = _currentFrame['fps'];
    final fraction = expectedDuration == null ||
            expectedDuration == Duration.zero ||
            outTimeMs == null
        ? null
        : (outTimeMs / expectedDuration!.inMicroseconds)
            .clamp(0.0, 1.0)
            .toDouble();

    final detailParts = <String>[
      if (fps != null && fps.isNotEmpty) 'fps $fps',
      if (speed != null && speed.isNotEmpty) 'speed $speed',
    ];

    onProgress?.call(SubprocessProgressUpdate(
      fraction: fraction,
      detail: detailParts.join(' | '),
    ));
    _currentFrame.clear();
    return true;
  }
}

class YtDlpProgressParser implements SubprocessProgressParser {
  static final RegExp _downloadLine = RegExp(
      r'^\[download\]\s+(\d+(?:\.\d+)?)%.*?(?:at\s+(.+?))?(?:\s+ETA\s+(.+))?$');
  static final RegExp _destinationLine =
      RegExp(r'^\[download\]\s+Destination:\s+(.+)$');

  @override
  bool handleLine(
    String line,
    void Function(SubprocessProgressUpdate update)? onProgress,
  ) {
    final destinationMatch = _destinationLine.firstMatch(line);
    if (destinationMatch != null) {
      onProgress?.call(SubprocessProgressUpdate(
        detail: 'Saving ${destinationMatch.group(1)}',
      ));
      return true;
    }

    final downloadMatch = _downloadLine.firstMatch(line);
    if (downloadMatch == null) {
      return false;
    }

    final percent = double.tryParse(downloadMatch.group(1) ?? '');
    final speed = downloadMatch.group(2)?.trim();
    final eta = downloadMatch.group(3)?.trim();
    final detailParts = <String>[
      if (speed != null && speed.isNotEmpty) speed,
      if (eta != null && eta.isNotEmpty) 'ETA $eta',
    ];

    onProgress?.call(SubprocessProgressUpdate(
      fraction:
          percent == null ? null : (percent / 100).clamp(0.0, 1.0).toDouble(),
      detail: detailParts.join(' | '),
    ));
    return true;
  }
}
