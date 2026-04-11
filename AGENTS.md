# AI Coding Guidelines for reddit-2-video

When working in this codebase, all AI coding assistants must adhere to the following strict guidelines based on existing project conventions:

## 1. Testing is Mandatory

- **1-to-1 Class Testing:** Every class must have an equivalent unit test.
- **Test Placement:** Tests must be placed in the `test/` directory. The structure should mirror the `lib/` directory (e.g., a class defined in `lib/config/background_video.dart` is tested in `test/config/background_video_test.dart`).
- **Integration Test Placement:** Real subprocess integration tests (such as FFmpeg smoke tests) must live under `test/integration/` so they are clearly separated from mocked unit tests.
- **Additional Implementations:** Any new feature, behavior change, or method implementation must include a corresponding test.
- **Run the Tests:** After making changes, always run the tests (e.g., using `dart test`) to verify the new implementation and ensure no regressions are introduced.
- **Mocking:** Use the `mocktail` package for mocking dependencies (see `test/mocks.dart` for examples of mock implementations).
- Tests must be grouped logically using `group()` and clearly described using `test()`.
- **Cross-Platform Paths:** Tests must not hardcode POSIX path separators in expected file paths. Use `package:path` helpers like `p.join(...)` or normalize both sides so tests pass on Windows and Unix CI runners.

## 2. Formatting and Styling

- **Formatter:** Always use the Prettier formatter before finalizing changes. The following rules from `.prettierrc` must be maintained:
  - Tab Width: 2
  - Use Tabs: false (Spaces only)
- **Dart Styling Conventions:** Follow standard, idiomatic Dart styling conventions. The project uses `package:lints/recommended.yaml` as defined in `analysis_options.yaml`. Ensure that generated code does not introduce new lint errors or warnings.
- **Styling Preference:** Use the logger helpers (like `printWarning` / `printSuccess`) for full-line colored prints instead of manually embedding ANSI color codes inside strings, unless specifically dealing with an integrated/interpolated string.

## 3. General Workflow

- **Custom Exceptions:** Utilize the project's highly structured custom exception system in `lib/exceptions/` (e.g., `ArgumentMissingException`, `FFmpegCommandException`) for all error states. Create new specific exception classes rather than throwing generic errors.
- **Command Handling:** Isolate all CLI parsing, validation, and user input strictly within `lib/command/` (e.g., `parsed_command.dart`). Do not mix UI/CLI logic with core business logic.
- **Strongly-Typed Models:** Represent all Reddit data using the established models in `lib/reddit/` (such as `RedditPost`, `RedditComment`, or `RedditUrl`). Avoid passing unstructured JSON maps or raw strings between functions.
- **Domain Separation:** Maintain the strict separation of concerns across existing domains: media generation logic in `lib/ffmpeg/`, subtitle generation in `lib/subtitles/`, configuration in `lib/config/`, and generic utilities in `lib/utils/`.
- **Subprocess Execution:** Centralize subprocess execution (`ffmpeg`, `ffprobe`, `yt-dlp`, etc.) through a shared utility in `lib/utils/` so test injection is done in one place, not per-class or per-method ad-hoc parameters.
- **Docs Theme Styling:** When styling the MkDocs site, use the Reddit-inspired palette already chosen for this repo, including `#336699` for UI text and link accents.
- **Docs Freshness Notes:** Hand-written docs pages should include a simple `Last reviewed: YYYY-MM-DD` note near the top. Do not add confidence labels.
- Write tests first or side-by-side with new implementations.

## 4. Continuous Learning (Self-Updating)

- **Update AGENT.md:** When the user tells you something valuable that will be useful in the future (such as a styling preference, architectural rule, or workflow optimization), you must update this `AGENT.md` file to preserve that knowledge.

## 5. End-to-End / HITL Testing

- **HITL Framework:** Use `overseer` for full human-in-the-loop end-to-end testing flows.
- **Matrix-Driven Runs:** Define scenario permutations in matrix YAML files under `test/hitl/`.
- **Executable HITL Entrypoint:** Keep overseer runners as standalone Dart entrypoints under `test/hitl/` so they can be launched with `dart run`.
