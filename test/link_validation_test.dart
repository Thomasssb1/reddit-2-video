import 'package:reddit_2_video/post/reddit_url.dart';
import 'package:test/test.dart';

void main() {
  group("Link validation", () {
    test("Reddit link directly to a post", () {
      expect(
          true,
          RedditUrl.validLink(
              'https://www.reddit.com/r/AskReddit/comments/15lfece/why_did_you_get_fired/'));
    });
    test("Reddit link directly to a post without title", () {
      expect(
          true,
          RedditUrl.validLink(
              'https://www.reddit.com/r/AskReddit/comments/15lfece'));
    });
    test("Reddit link directly to a post via share", () {
      // A link to a post that has queries - copied from share option on post
      expect(
          true,
          RedditUrl.validLink(
              'https://www.reddit.com/r/AskReddit/comments/1gika69/what_is_one_never_have_never_will_thing_for_you/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button'));
    });
    test("Reddit link to homepage", () {
      expect(false, RedditUrl.validLink('https://www.reddit.com/'));
    });
    test("Reddit link to subreddit", () {
      expect(false, RedditUrl.validLink('https://www.reddit.com/AskReddit'));
    });
    test("Link to a non-reddit site", () {
      expect(false, RedditUrl.validLink('https://www.google.com/'));
    });
    test("Use a string instead of a link", () {
      expect(false, RedditUrl.validLink('reddit-2-video'));
    });
  });
}
