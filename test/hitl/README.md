# HITL Testing with Overseer

Last reviewed: 2026-04-09

This directory contains human-in-the-loop (HITL) end-to-end test scenarios using [overseer](https://pub.dev/packages/overseer).

## Structure

- `reddit_video_hitl.dart`  
  Overseer runner entrypoint.
- `matrices/`  
  Focused matrix files (one feature area per YAML).
- `reports/`  
  Generated Overseer Markdown reports.
- `.overseer.lock`  
  Resume state file for interrupted runs (gitignored).

## Available matrices

- `matrices/core.matrix.yaml`  
  Core post/comments generation flow.

## Run HITL

Run default matrix (`core`):

```bash
dart run test/hitl/reddit_video_hitl.dart
```

Run a specific matrix:

```bash
dart run test/hitl/reddit_video_hitl.dart test/hitl/matrices/core.matrix.yaml
```

## Interactive controls (Overseer)

- `y` = pass checklist item
- `n` = fail checklist item
- `s` = skip checklist item
- `r` = retry current case generation
- `q` = save progress and quit

## Notes

- HITL runs are manual and are not intended to be fully executed in CI.
- Reports are written under `test/hitl/reports/`.
- If interrupted, rerun the same matrix to resume from `.overseer.lock`.
- Keep matrices focused by feature area when new scenarios are added.

## Troubleshooting

### `The specified language version is too high ... highest supported is 3.2`

`overseer` requires Dart >= 3.3.0.

Check your active SDK:

```bash
dart --version
```

If it is below 3.3, upgrade Dart and refresh dependencies:

```bash
dart pub get
```

Then rerun HITL using the full runner path from repo root:

```bash
dart run test/hitl/reddit_video_hitl.dart
```
