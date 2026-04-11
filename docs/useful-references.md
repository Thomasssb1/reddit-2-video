# Useful References

This page collects example commands, placeholder embedded videos, and external links.

## Example Commands

Generate a video from an `AskReddit` post using comments:

```bash
reddit-2-video --subreddit AskReddit --type comments --count 10 --alternate=on,on --title-color H0000FF --output example-1
```

<video
  controls
  preload="metadata"
  width="720"
  poster="assets/images/examples/comments-flow-poster.webp"
>
  <source
    src="https://github.com/Thomasssb1/reddit-2-video/releases/download/v1.1.0/example-1.mp4"
    type="video/mp4"
  />
</video>

Generate a horror-style story from `nosleep`:

```bash
reddit-2-video --subreddit nosleep --horror --post-confirmation --music <path-to-music> --youtube-short --output example-2.mp4
```

<video
  controls
  preload="metadata"
  width="720"
  poster="assets/images/examples/horror-story-poster.webp"
>
  <source
    src="https://github.com/Thomasssb1/reddit-2-video/releases/download/v1.1.0/example-2.mp4"
    type="video/mp4"
  />
</video>

Generate repeated output from `pettyrevenge` posts:

```bash
reddit-2-video --subreddit pettyrevenge --repeat 3 --no-nsfw --censor --sort top --output example-3
```

<div
  style="
    display: grid;
    gap: 1rem;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    align-items: start;
  "
>
  <video
    controls
    preload="metadata"
    width="240"
    poster="assets/images/examples/youtube-short-poster.webp"
    style="width: 100%;"
  >
    <source
      src="https://github.com/Thomasssb1/reddit-2-video/releases/download/v1.1.0/example-3-1.mp4"
      type="video/mp4"
    />
  </video>
  <video
    controls
    preload="metadata"
    width="240"
    poster="assets/images/examples/youtube-short-poster.webp"
    style="width: 100%;"
  >
    <source
      src="https://github.com/Thomasssb1/reddit-2-video/releases/download/v1.1.0/example-3-2.mp4"
      type="video/mp4"
    />
  </video>
  <video
    controls
    preload="metadata"
    width="240"
    poster="assets/images/examples/youtube-short-poster.webp"
    style="width: 100%;"
  >
    <source
      src="https://github.com/Thomasssb1/reddit-2-video/releases/download/v1.1.0/example-3-3.mp4"
      type="video/mp4"
    />
  </video>
</div>

Generate a multi-post video:

```bash
reddit-2-video --subreddit dadjokes --type multi --count 3 --sort rising --framerate 75 --output example-4.mp4
```

<video
  controls
  preload="metadata"
  width="720"
  poster="assets/images/examples/multi-post-poster.webp"
>
  <source
    src="https://github.com/Thomasssb1/reddit-2-video/releases/download/v1.1.0/example-4.mp4"
    type="video/mp4"
  />
</video>

Generate from a single Reddit post URL:

```bash
reddit-2-video --subreddit https://www.reddit.com/r/TrueOffMyChest/comments/1sfywpl/my_husband_has_started_wearing_makeup_and_i_hate/ --end-card <path-to-gif> -v --output example-5
```

<video controls preload="metadata" width="720" poster="assets/images/examples/direct-post-poster.webp">
  <source src="https://github.com/Thomasssb1/reddit-2-video/releases/download/v1.1.0/example-5.mp4" type="video/mp4">
</video>

Notes:

- The URLs above are placeholders and will 404 until you upload the release assets.
- The poster image paths are placeholders and can be swapped to `.png`, `.jpg`, or `.webp`.
- If you prefer, each example can link out to a release asset instead of embedding inline video.

## External References

- [Project README](https://github.com/Thomasssb1/reddit-2-video/blob/master/README.md)
- [Project Wiki](https://github.com/Thomasssb1/reddit-2-video/wiki)
- [GitHub Releases](https://github.com/Thomasssb1/reddit-2-video/releases)
- [FFmpeg](https://ffmpeg.org/about.html)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)

---

Last reviewed: 2026-04-08
