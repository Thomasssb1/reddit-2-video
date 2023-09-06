import 'package:test/test.dart';
import 'package:reddit_2_video/utils/http.dart';

void main() {
  group("Link validation", () {
    test("Reddit link directly to a post", () {
      bool isValidLink = validateLink('https://www.reddit.com/r/AskReddit/comments/15lfece/why_did_you_get_fired/');
      expect(true, isValidLink);
    });
    test("Reddit link to homepage", () {
      bool isValidLink = validateLink('https://www.reddit.com/');
      expect(false, isValidLink);
    });
    test("Reddit link to subreddit", () {
      bool isValidLink = validateLink('https://www.reddit.com/AskReddit');
      expect(false, isValidLink);
    });
    test("Link to a non-reddit site", () {
      bool isValidLink = validateLink('https://www.google.com/');
      expect(false, isValidLink);
    });
    test("Use a string instead of a link", () {
      bool isValidLink = validateLink('reddit-2-video');
      expect(false, isValidLink);
    });
  });
}
