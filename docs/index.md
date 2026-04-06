# reddit-2-video

`reddit-2-video` generates Reddit narration videos from a subreddit feed or a specific Reddit post URL. It combines post content, comments, subtitles, background media, and export settings into a single CLI workflow aimed at short-form video output.

## Overview

The project is built around one default generation command plus a small set of support commands. The main workflow is:

1. Pick a subreddit or post URL.
2. Resolve the content to read out.
3. Choose narration strategy.
4. Render the final video and optionally split it for short-form platforms.

The command surface is documented in [CLI Reference](cli.md). For practical behavior notes, built-in assets, and command interactions that do not fit neatly into a generated flag list, see [Quirks and Defaults](quirks-and-defaults.md).

## Output Model

Generated output is not just a single audio-over-video pass. The tool builds a sequence of visual sections, loading/progress style moments, and subtitle-driven content blocks that together form the final rendered video.

Common output-related options include:

- `--output` to control the output basename or target file path.
- `--file-type` to choose the output container.
- `--youtube-short` to split long renders into short-form segments.
- `--end-card` and `--end-card-length` to append an ending sequence.
- `--max-length` to stop generation at a logical boundary.

You can document specific visual examples and embedded videos on the [Useful References](useful-references.md) page.

## Runtime Behavior

`--verbose` enables extra process output that is useful when you want to inspect FFmpeg or other generation details during a run. For normal usage you can leave it off and keep the CLI quieter.

Developer mode is covered separately in [Contributing](contributing.md).

---

Last reviewed: 2026-04-07
