// need to figure out what happens if the segment contains no punctuation

int maxLength = 3000;
List<String> splitText(String text) {
  List<String> newText = [];
  RegExp punctuationMatch = RegExp(r"(\.|\?|!|\u2026)");
  List<dynamic> endPoints =
      punctuationMatch.allMatches(text).expand<int>((e) => [e.end]).toList();
  endPoints.insert(0, 0);
  int prevIndex = 0;
  for (int i = 0; i < endPoints.length; i++) {
    print(endPoints[i]);
    print(endPoints[i] - endPoints[prevIndex]);
    if (endPoints[i] - endPoints[prevIndex] >= maxLength) {
      newText.add(text.substring(endPoints[prevIndex], endPoints[i - 1]));
      prevIndex = i - 1;
    } else if (i == endPoints.length - 1) {
      newText.add(text.substring(endPoints[prevIndex], endPoints[i]));
      newText.add(text.substring(endPoints[i], text.length));
    }
  }
  return newText;
}
