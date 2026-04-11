class SubtitleLineData {
  String text;
  final Duration end;
  final Duration start;
  final int lineNumber;

  SubtitleLineData({
    required this.text,
    required this.end,
    required this.start,
    required this.lineNumber,
  });

  bool isFinalLine(int lineCount) => lineNumber == lineCount;

  @override
  String toString() {
    return text;
  }
}
