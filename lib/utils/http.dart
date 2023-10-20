import 'package:reddit_2_video/utils/prettify.dart';
import 'dart:io';
import 'package:http/http.dart';

/// check if the http request contained an error
///
/// returns [true] if not and [false] if so
bool checkStatusCode(
  Response response,
  String type,
) {
  if (response.statusCode == 200) {
    return true;
  } else if (response.statusCode == 404) {
    printError(
        "Endpoint could not be found. Perhaps the reddit endpoint being accessed is down or unavailable. Please try again later. If the problem persists, post this as an issue on github https://github.com/Thomasssb1/reddit-2-video/issues\nError: ${response.statusCode}\nReason: ${response.reasonPhrase}");
  } else if (response.statusCode == 400) {
    printError(
        "Incorrect data was sent to the server. If the problem persists, post this as an issue on github https://github.com/Thomasssb1/reddit-2-video/issues along with the data below.\nError:${response.statusCode}\nIncorrect data being sent: $type\n${response.body}\nReason: ${response.reasonPhrase}");
  } else if (response.statusCode == 303) {
    printError(
        "Error occurred whilst attempting to get post data. It is likely that the endpoint used is inactive and needs to be changed. Post this as an issue on github https://github.com/Thomasssb1/reddit-2-video/issues if the problem persists.\nError: ${response.statusCode}\nReason: ${response.reasonPhrase}");
  } else {
    printError(
        "An unknown error occurred when attempting to access the link.\nError: ${response.statusCode}\nReason: ${response.reasonPhrase}\n${response.body}");
  }
  return false;
}

bool validateLink(String link) {
  bool isLink = RegExp(r'''(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w\.-]*)''').hasMatch(link);
  if (isLink) {
    Uri uriLink = Uri.parse(link);
    List<String> paths = uriLink.pathSegments;
    if (paths.isNotEmpty) {
      if (paths.last == '') {
        paths = paths.sublist(0, paths.length - 1);
      }
      if (paths.length == 5) {
        if (uriLink.host == 'www.reddit.com' && paths[0] == 'r' && paths[2] == 'comments') {
          return true;
        } else {
          printError(
              "Unable to use the link you have provided along with the --subreddit arg, try using another link that links directly to the reddit post.");
          exit(0);
        }
      } else {
        printError(
            "The link that you have provided along with the --subreddit arg is not a proper link that links directly to a reddit post. Re-run the command but instead with a reddit link that links directly to the reddit post.");
        exit(0);
      }
    } else {
      printError(
          "Unable to use the link you have provided along with the --subreddit arg, ensure that you are using a link that links directly to the reddit post");
      exit(0);
    }
  }
  return false;
}
