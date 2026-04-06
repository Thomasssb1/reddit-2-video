# Useful References

This page is intended to hold practical examples, embedded videos, and command walkthroughs.

## Example Commands

Generate a video from an `AskReddit` post using comments:

```bash
reddit-2-video --subreddit AskReddit --type comments --count 10 --alternate=on,on
```

Generate a horror-style story from `nosleep`:

```bash
reddit-2-video --subreddit nosleep --horror --post-confirmation
```

Generate repeated output and split for short-form upload:

```bash
reddit-2-video --subreddit pettyrevenge --repeat 5 --no-nsfw --youtube-short --censor
```

Generate a multi-post video:

```bash
reddit-2-video --subreddit dadjokes --type multi --sort rising --framerate 75
```

Generate from a single Reddit post URL:

```bash
reddit-2-video --subreddit https://www.reddit.com/r/TrueOffMyChest/comments/1850nn6/my_husband_is_cheating_on_me_with_our_best_friend/ --end-card <path-to-gif> -v
```

<!-- TODO
## What To Embed Here

Suggested content for this page:

- Example output videos for each command pattern.
- Visual breakdowns of loading screens and section transitions.
- Before and after comparisons for options like `--verbose`, `--horror`, or `--youtube-short`.
- Small “why this flag matters” notes alongside each example.
-->

## External References

- [Project README](https://github.com/Thomasssb1/reddit-2-video/blob/master/README.md)
- [Project Wiki](https://github.com/Thomasssb1/reddit-2-video/wiki)
- [GitHub Releases](https://github.com/Thomasssb1/reddit-2-video/releases)
- [whisper_timestamped](https://github.com/linto-ai/whisper-timestamped)
- [FFmpeg](https://ffmpeg.org/about.html)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)

---

Last reviewed: 2026-04-07
