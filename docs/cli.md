# CLI Reference

This page is generated from `lib/command/parsed_command.dart`. Update the CLI parser and redeploy to refresh this reference.

## Command Overview

```bash
reddit-2-video --subreddit AskReddit [options]
reddit-2-video flush --post <reddit-post-id>
reddit-2-video install
```

## Default Command

The default command generates videos from a subreddit or a Reddit post URL.

```bash
reddit-2-video --subreddit AskReddit [options]
```

### Options

#### `--subreddit`

- Type: `option`
- Required: yes

#### `--sort`

- Type: `option`
- Short flag: `-s`
- Default: `top`
- Allowed: `hot`, `new`, `top`, `rising`

#### `--comment-sort`

- Type: `option`
- Default: `best`
- Allowed: `top`, `best`, `new`, `controversial`, `old`, `q&a`

#### `--count`

- Type: `option`
- Default: `8`
- Description: Maximum number of comments.

#### `--type`

- Type: `option`
- Default: `post`
- Allowed: `comments`, `post`, `multi`

#### `--alternate`

- Type: `multi-option`

#### `--title-color`

- Type: `option`
- Value: `<RRGGBB>`
- Default: `FF0000`

#### `--post-confirmation`

- Type: `flag`

#### `--nsfw`

- Type: `flag`

#### `--spoiler`

- Type: `flag`
- Description: Add a spoiler to the video which hides the image/text before showing for 3s.

#### `--ntts`

- Type: `flag`

#### `--voice`

- Type: `option`
- Default: `Matthew`
- Description: The voice to use for AWS Polly tts.

#### `--repeat`

- Type: `option`
- Value: `integer`
- Default: `1`
- Description: How many times the program should repeat - does not work for links but works for subreddits.

#### `--video`

- Type: `option`
- Short flag: `-p`
- Value: `<path-to-video>`

#### `--music`

- Type: `multi-option`
- Value: `path,volume`

#### `--horror`

- Type: `flag`
- Description: Lowers the pitch from TTS for creepy stories.

#### `--output`

- Type: `option`
- Short flag: `-o`
- Default: `final`
- Description: Location where the generated file will be stored.

#### `--file-type`

- Type: `option`
- Default: `mp4`
- Allowed: `mp4`, `avi`, `mov`, `flv`

#### `--framerate`

- Type: `option`
- Default: `45`
- Allowed: `15`, `30`, `45`, `60`, `75`, `120`, `144`
- Description: The framerate used when generating the video - using a higher framerate will take longer and produce a larger file.

#### `--censor`

- Type: `flag`
- Description: Censors any innapropriate words. This will only work when using AWS and you need to upload the defaults/lexicons/lexeme.xml file as a lexicon in AWS console.

#### `--end-card`

- Type: `option`
- Value: `<path-to-gif>`
- Description: Path to a gif & audio that will play at the end of the video.

#### `--verbose`

- Type: `flag`
- Short flag: `-v`

#### `--override`

- Type: `flag`
- Short flag: `-y`

#### `--youtube-short`

- Type: `flag`
- Description: Whether to split the final generated video into ~1 minute shorts.

#### `--help`

- Type: `flag`
- Short flag: `-h`

#### `--delay`

- Type: `option`
- Default: `1`
- Description: The pause in seconds between TTS audio clips. Only applies to comments and multi types.

#### `--end-card-length`

- Type: `option`
- Description: Override the end-card duration in seconds. If omitted, duration is inferred from the gif/video file. Required when the end-card is a static image.

#### `--max-length`

- Type: `option`
- Description: Maximum video length in seconds. Generation stops at a logical boundary once this limit is reached. Ignored for post type.

## `install` Command

Installs or bootstraps runtime dependencies. In practice this is a starting point for setup rather than a complete environment installer.

```bash
reddit-2-video install
```

### Options

This command has no command-specific options.

## `flush` Command

Manages visited-post state so you can remove a post from the visited log and allow it to be reused.

```bash
reddit-2-video flush --post <reddit-post-id>
```

### Options

#### `--post`

- Type: `option`
- Short flag: `-p`
- Description: Remove a specific reddit post from the visited log.
