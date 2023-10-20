int maxLength = 3000;
List<String> splitText(String text) {
  List<String> newText = [];
  RegExp punctuationMatch = RegExp(r"(\.|\?|!|\u2026)");
  List<dynamic> endPoints = punctuationMatch.allMatches(text).expand<int>((e) => [e.end]).toList();
  endPoints.insert(0, 0);
  int prevIndex = 0;
  for (int i = 0; i < endPoints.length; i++) {
    if (endPoints[i] - endPoints[prevIndex] >= maxLength) {
      newText.add(text.substring(endPoints[prevIndex], endPoints[i - 1]));
      prevIndex = i - 1;
    } else if (i == endPoints.length - 1) {
      if (i != 0) {
        newText.add(text.substring(endPoints[prevIndex], endPoints[i]));
      }
      newText.add(text.substring(endPoints[i], text.length));
    }
  }
  List<String> tempText = [];
  RegExp splitMatch = RegExp('.{1,$maxLength}');
  for (final line in newText) {
    if (line.length > maxLength) {
      tempText.addAll(splitMatch.allMatches(line).map((e) => e[0]!).toList());
    } else {
      tempText.add(line);
    }
  }
  return tempText;
}
