class SubtitleLineData {
  final String highlightColour = '#00FFFF';

  String text;
  final int end;
  final int start;
  final bool finalWord;
  final segmentID;

  SubtitleLineData({
    required this.text,
    required this.end,
    required this.start,
    required this.finalWord,
    required this.segmentID,
  });

  void addHighlight() {
    text = "{\\c&$highlightColour}$text";
  }

  bool isFinalSegment(int segmentCount) {
    return segmentCount == segmentID;
  }

  bool get isFinalWord => finalWord;

  @override
  String toString() {
    return text;
  }
}
