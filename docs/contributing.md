# Contributing

This page covers the source-based developer workflow rather than the precompiled binary workflow.

## Developer Setup

Clone the repository:

```bash
git clone https://github.com/Thomasssb1/reddit-2-video.git
```

Activate the repo as a path dependency so you can rebuild and run it while developing:

```bash
dart pub global activate --source path reddit-2-video
```

That lets you run `reddit-2-video` across your file system while iterating on the local source.

## Development Notes

- End users should prefer release binaries.
- Contributors will need Dart and the rest of the source build toolchain.
- Runtime dependencies such as `ffmpeg`, `ffprobe`, `yt-dlp`, and `whisper_timestamped` are still relevant for real execution paths.

## Checked-In State Filter

This git filte is recommended so generated state files do not create noisy diffs unnecessarily:

```bash
git config filter.cleanJsonState.clean "jq '(if has(\"_last_updated\") then ._last_updated=null else . end) | (if has(\"visited\") then .visited=[] else . end)'"
git config filter.cleanJsonState.smudge cat
git config filter.cleanJsonState.required true
git add --renormalize .temp/visited_log.json defaults/lexicons/lexemes.config.json
```

## Build Notes

If you are compiling the executable yourself, refer back to the repository README for the current compile command and platform-specific output naming.

---

Last reviewed: 2026-04-07
