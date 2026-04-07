# Testing

Testing is part of the expected workflow for this repository and is enforced by CI.

## Unit and Integration Tests

Run the full suite with:

```bash
dart test
```

The repository’s CI pipeline runs tests as part of its validation flow, alongside formatting and analysis checks. Changes are expected to keep that pipeline passing.

## Test Layout

- Unit tests live under `test/`.
- Real subprocess smoke tests live under `test/integration/`.
- HITL scenarios live under `test/hitl/`.

## HITL

Full human-in-the-loop runs use [overseer](https://github.com/Thomasssb1/overseer). Scenario permutations are defined in matrix YAML files under `test/hitl/`, and executable runners live there as standalone Dart entrypoints.

When reviewing HITL output, focus on:

- Which scenario matrix was executed.
- Whether the generated output matched the intended content path.
- Any failures tied to subprocess tooling, subtitles, or output segmentation.
- The run artifacts and reports produced by the overseer flow for that scenario.

If you add more detailed report examples later, this page is the right place to document how to interpret them.

---

Last reviewed: 2026-04-07
