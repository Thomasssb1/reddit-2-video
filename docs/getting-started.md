# Getting Started

There are two main ways to start using `reddit-2-video`

## Use a Precompiled Release

The easiest way to get started is to download one of the project releases.

This is the preferred setup to quickly get into running the tool.

### Add the Binary to Path

Add the folder containing the `reddit-2-video` binary to your system `PATH`.

If you are working from a cloned checkout, that usually means adding the `reddit-2-video/bin` directory. The exact steps vary by operating system. The [README](https://github.com/Thomasssb1/reddit-2-video/blob/master/README.md#setup) includes a cross-platform guide for updating your path.

### Install Runtime Dependencies

For normal usage you do not need Dart, but you do need the runtime tools the binary calls:

- `ffmpeg`
- `ffprobe`
- `yt-dlp`
- `whisper_timestamped`

> AWS Polly is currently the only supported text synthesis backend, so AWS CLI setup is required.

### Use the Install Command

You can start with:

```bash
reddit-2-video install
```

Treat this as a bootstrap command rather than a guaranteed full installer. It is a good starting point, but you should still verify that `ffmpeg`, `ffprobe`, `yt-dlp`, and `whisper_timestamped` are available afterwards.

## Compile It Yourself

If releases do not fit your platform or you want to work from source, compile the executable yourself.

### Source Build Dependencies

For a source build you will need dart as well as the other runtime dependencies.

### Compile the Executable

From the repository root:

```bash
dart compile exe bin/reddit-2-video.dart --output=bin/reddit-2-video
```

On Windows, compile with the `.exe` extension:

```bash
dart compile exe bin/reddit-2-video.dart --output=bin/reddit-2-video.exe
```

### Developer-Friendly Activation

If you are iterating on the source and want to run the command from anywhere on your machine, you can activate the repo as a path dependency:

```bash
dart pub global activate --source path reddit-2-video
```

That is more of a contributor workflow than an end-user setup, but it is useful if you are actively modifying the project.

## First Run

Once your chosen setup path is complete, a minimal run looks like this:

```bash
reddit-2-video --subreddit AmItheAsshole
```

## Next Steps

- Use [CLI Reference](cli.md) for the current flag and command surface.
- Use [Quirks and Defaults](quirks-and-defaults.md) for behavior notes and built-in asset details.
- Use [Useful References](useful-references.md) for example commands and embedded walkthroughs.

---

Last reviewed: 2026-04-07
