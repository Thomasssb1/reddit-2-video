# Quirks and Defaults

This page captures behavior that is useful in practice but easy to miss if you only skim the flag list.

## Base Command

The base command used for every interaction is:

```bash
reddit-2-video
```

That executable name is the entrypoint for:

- the default generation command
- `flush`
- `install`

## Flag Negation

Flags can generally be turned off with the `--no-...` form.

Examples:

```bash
reddit-2-video --no-post-confirmation
reddit-2-video --no-nsfw
reddit-2-video --no-verbose
```

This is especially useful when you want to override a default-enabled flag such as `--nsfw`.

## Current Command Notes

There are three top-level commands:

- `reddit-2-video`
- `reddit-2-video flush`
- `reddit-2-video install`

The default command is the one that generates videos. `flush` manages visited-log state. `install` is a setup/bootstrap command.

## Common Interactions and Contradictions

Some options affect or override each other:

### Content selection

- `--subreddit` is required for the default command and can be either a subreddit name or a full Reddit post URL.
- If `--subreddit` is a direct Reddit post URL and `--type post` is used, `--count` is ignored and a warning is logged.
- If `--subreddit` is a direct Reddit post URL and `--type multi` is used, the command is invalid.
- `--repeat` is only used for subreddit-based generation. A direct post link resolves to one post.

### End cards

- `--end-card-length` is not strictly necessary unless you are using an image, as the duration can be inferred from the file itself. If provided, it will override the inferred duration.
- If end-card duration cannot be inferred from a gif/video, the duration falls back to `5s` and logs a warning.

### Output and working files

- `--override` controls whether existing output files are replaced automatically.
- `--keep-temp` stops cleanup of the `.temp` directory on exit, which is useful for debugging and HITL inspection.

### Unimplemented behavior

- `--spoiler` currently exists but is not implemented; generation continues with a warning.

## Voices and Lexicons

Voice and lexicon behavior is driven by checked-in config files rather than a hardcoded docs list.

### Voices

Voices are loaded from:

`defaults/voice.config.json`

Important details:

- `--voice` picks a voice by name from that config file.
- voices can be marked as `disabled` which removes it from being selected when voice alternation is enabled.
- enabling or disabling `--ntts` will affect whether neural tts is selected during alternation or manual selection.
- if the requested voice is missing or incompatible, the app falls back and logs a warning

### Lexicons

Lexicons are configured in:

`defaults/lexicons/lexemes.config.json`

The shipped lexicon files currently include:

- `censor.xml`
- `abbreviations.xml`

These control transformations such as censorship or abbreviation expansion during synthesis flows.
You can add more lexicon files, following the [AWS Polly format](https://docs.aws.amazon.com/polly/latest/dg/API_Lexicon.html#:~:text=The%20content%20of%20a%20lexicon%20must%20be%20in%20PLS%20format.) and including them in the lexemes config file. All listed lexicon files will be loaded into AWS polly and applied during text synthesis.

## The `defaults/` Directory

The `defaults/` directory is the built-in asset/config bundle the app expects at runtime.

Current shipped files include:

- [`defaults/default.ass`](/Users/thoma/Programs/reddit-2-video/defaults/default.ass): subtitle styling/template base
- [`defaults/fonts/verdana.ttf`](/Users/thoma/Programs/reddit-2-video/defaults/fonts/verdana.ttf): bundled font asset
- [`defaults/voice.config.json`](/Users/thoma/Programs/reddit-2-video/defaults/voice.config.json): voice registry and capability metadata
- [`defaults/lexicons/lexemes.config.json`](/Users/thoma/Programs/reddit-2-video/defaults/lexicons/lexemes.config.json): lexicon registry
- [`defaults/lexicons/censor.xml`](/Users/thoma/Programs/reddit-2-video/defaults/lexicons/censor.xml): censorship lexicon
- [`defaults/lexicons/abbreviations.xml`](/Users/thoma/Programs/reddit-2-video/defaults/lexicons/abbreviations.xml): abbreviation expansion lexicon
- [`defaults/silence.mp3`](/Users/thoma/Programs/reddit-2-video/defaults/silence.mp3): silence filler/empty-noise asset
- [`defaults/n_Dv4JMiwK8.mp4`](/Users/thoma/Programs/reddit-2-video/defaults/n_Dv4JMiwK8.mp4): background video asset (downloaded on first pass)

## Background Video Download and Reuse

The background video only needs to be downloaded once per YouTube video id.

When a background video is needed, the app downloads it into `defaults/` using the YouTube video id as the filename. If that file already exists, later runs skip the download step and reuse the cached file instead.

That means:

- the first run may download the background source video
- later runs reuse the same cached source file from `defaults/`
- each generation still creates its own working clip for the current output

So the source download is reused, while the per-run cut video is still regenerated for each generation.

## Output Defaults

Some defaults are worth remembering:

- default output basename is `final`
- default file type is `mp4`
- default framerate is `45`
- default delay between TTS clips is `1s`
- default comment count threshold is `8`

Always treat the generated [CLI Reference](cli.md) as the source of truth for current defaults, because older wiki material may describe behavior from previous iterations of the project.

---

Last reviewed: 2026-04-07
