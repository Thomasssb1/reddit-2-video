# Implementing Parameters & Unit Tests

## 1. New CLI Parameters
- [/] Create `MaxLengthExceededException` in `lib/exceptions/`
- [ ] Export it from `lib/exceptions/exceptions.dart`
- [ ] Add `--delay`, `--end-card-length`, `--max-length` options to `parsed_command.dart`
- [ ] Add typed getters for the three new options

## 2. EndCard duration auto-detection
- [ ] Make `EndCard` async-capable or accept duration from ffprobe
- [ ] Add ffprobe probe logic for gif/video duration
- [ ] Warn if `--end-card-length` overrides an inferable value

## 3. Subtitles.dart changes
- [ ] Wire `delay` from command (only for `comments`/`multi` types)
- [ ] Add `maxLength` guard in `parse()` with per-type logic and warnings

## 4. Unit Tests
- [ ] `test/command/parsed_command_test.dart`
- [ ] `test/ffmpeg/ffmpeg_command_test.dart`
- [ ] `test/subtitles/subtitles_test.dart`
- [ ] `test/subtitles/subtitle_test.dart`
- [ ] `test/reddit_video_test.dart`
- [ ] `test/reddit/reddit_url_test.dart`

## 5. Verification
- [ ] `dart test` — all tests pass
