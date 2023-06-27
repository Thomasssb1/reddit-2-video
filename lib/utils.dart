List<String> splitComments(String comment) {
  // the max amount of characters on screen
  comment = comment
      .replaceAll(RegExp(r'''[^\w\d' "]+'''), ' ')
      .replaceAll(
          RegExp(
              r'''(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w\.-]*)'''),
          ' ')
      .replaceAll(RegExp(' {2,}'), ' ')
      .trim();
  const int splitAmount = 18;
  String commentPiece = "";
  List<String> newComment = [];
  for (final word in comment.split(
    ' ',
  )) {
    if (commentPiece.length + word.length < splitAmount) {
      commentPiece += "$word ";
    } else {
      newComment.add(commentPiece.substring(0, commentPiece.length - 1));
      commentPiece = "$word ";
    }
  }
  newComment.add(commentPiece.substring(0, commentPiece.length - 1));
  return newComment;
}

String lengthCalculation(String message, String startTime) {
  // start (hh:mm:ss,ms)--> end (hh:mm:ss,ms)
  int timePerChar = 50;

  int prevMinutes = int.parse(startTime[2] + startTime[3]);
  int prevSeconds = int.parse(startTime[5] + startTime[6]);
  int prevMilliseconds = int.parse(startTime.substring(8)) * 10;
  Duration calculatedTime = Duration(
      milliseconds:
          (prevMilliseconds + (prevSeconds * 1000) + (prevMinutes * 60000)) +
              (message.length * timePerChar));
  if (calculatedTime.inHours > 0) {
    return "Somehow the time has gone over an hour for the video.. Aborting.";
  }
  String newTime =
      "0:${calculatedTime.inMinutes.remainder(60).toString().padLeft(2, '0')}:${calculatedTime.inSeconds.remainder(60).toString().padLeft(2, '0')}.${calculatedTime.inMilliseconds.remainder(1000).toString().padRight(2, '0').substring(0, 2)}";
  return newTime;
}
