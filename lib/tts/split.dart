int maxLength = 600;

// need to figure out what happens if the segment contains no bullet points

/*
List<String> splitText(String text){
  List<String> newText = [];
  RegExp punctuationMatch = RegExp(r"(\.|\?|!|\u2026)");
  List<dynamic> endPoints = punctuationMatch.allMatches(text).expand<int>((e) => [e.end]).toList();
  endPoints.insert(0, 0);
  int prevIndex = 0;
  for (int i = 0; i < endPoints.length; i++){
    if (endPoints[i] - endPoints[prevIndex] >= maxLength){
      newText.add(text.substring(endPoints[prevIndex], endPoints[i-1]));
      prevIndex = i;
    }else if (i == endPoints.length-1){
      newText.add(text.substring(endPoints[prevIndex], text.length));
    }
  }
  return newText;
}*/

List<String> splitText(String text) {
  int splitAmount = 200;
  RegExp splitMatch = RegExp('.{1,$splitAmount}');
  return splitMatch.allMatches(text).map((e) => e[0]!).toList();
}
