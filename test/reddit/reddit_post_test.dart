import 'package:deep_pick/deep_pick.dart';
import 'package:test/test.dart';

import 'package:reddit_2_video/reddit/reddit_post.dart';

void main() {
  group("RedditPost constructor", () {
    test("from url", () async {
      RedditPost post = await RedditPost.fromUrl(
        url:
            "https://www.reddit.com/r/TrueOffMyChest/comments/1850nn6/my_husband_is_cheating_on_me_with_our_best_friend/",
      );
      expect(post.title, "My husband is cheating on me with our best friend");
      expect(
          post.body,
          contains(
              "My ex husband and my ex best friend as no surprise are now in an actual relationship after the ex best friend’s husband found out about the affair."));
      expect(post.id, "1850nn6-t5_2yuqy");
      expect(post.subreddit, "TrueOffMyChest");
      expect(post.subredditId, "t5_2yuqy");
      expect(
          post.created,
          DateTime.fromMillisecondsSinceEpoch(
              Duration(seconds: 1701083780).inMilliseconds));
      expect(post.nsfw, false);
      expect(post.spoiler, false);
      expect(post.stickied, false);
      expect(post.hasMedia, false);
    });
    test("from id", () async {
      Pick json = Pick({
        "subreddit": "TrueOffMyChest",
        "subreddit_id": "t5_2yuqy",
        "title": "My husband is cheating on me with our best friend",
        "selftext":
            "My ex husband and my ex best friend as no surprise are now in an actual relationship after the ex best friend’s husband found out about the affair.",
        "id": "1850nn6",
        "created_utc": 1701083780,
        "spoiler": false,
        "stickied": false,
        "over_18": false,
        "media": null,
        "comment_count": 0,
      });
      RedditPost post =
          RedditPost.fromId(subreddit: "t5_2yuqy", id: "1850nn6", json: json);
      expect(post.title, "My husband is cheating on me with our best friend");
      expect(post.body,
          "My ex husband and my ex best friend as no surprise are now in an actual relationship after the ex best friend’s husband found out about the affair.");
      expect(post.id, "1850nn6-t5_2yuqy");
      expect(post.subreddit, "TrueOffMyChest");
      expect(post.subredditId, "t5_2yuqy");
      expect(
          post.created,
          DateTime.fromMillisecondsSinceEpoch(
              Duration(seconds: 1701083780).inMilliseconds));
      expect(post.nsfw, false);
      expect(post.spoiler, false);
      expect(post.stickied, false);
      expect(post.hasMedia, false);
      expect(post.commentCount, 0);
    });
  });
}
