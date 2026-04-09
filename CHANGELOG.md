# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-04-09

### Added

- A full MkDocs documentation site, including getting started, CLI, testing, contributing, and defaults documentation.
- Broad automated coverage across unit, integration, CI, release, and HITL test workflows.

### Changed

- Optimised output customization with end cards, background music, background video overrides, and YouTube Shorts style splitting.
- Improved voice and lexicon handling with multi-lexicon support and updated default voice configuration files.
- Reworked command parsing and validation into a dedicated command layer with clearer CLI behavior and help output.
- Refactored the media generation pipeline around shared subprocess execution, richer progress reporting, and improved error surfacing for external tools.
- Switched subtitle and timing generation away from `whisper_timestamped` toward the current Polly speech-mark based flow, offloading heavy computation to the cloud - speeding up video generation.
- Improved Windows and cross-platform path handling, output overwrite handling, and repeated generation behavior.
- Reorganized the codebase into clearer domains for command parsing, config, Reddit models, subtitles, ffmpeg, and utilities.

### Removed

- The old `--dev` workflow flag. It is now automatically configured.
- The legacy bundled `defaults/config.json` configuration file.
- The old text-based visited log in favor of JSON-backed state tracking.
- The previous `whisper_timestamped` dependency and related legacy TTS/subtitle helpers.

## [1.0.0] - 2024-01-08

### Added

- Initial version.
