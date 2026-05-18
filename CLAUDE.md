# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Luciq Flutter SDK — the official Flutter plugin for Luciq, an Agentic Observability Platform for Mobile. Provides bug reporting, crash reporting, APM, surveys, in-app replies, feature requests, and session replay. Current version: 19.2.2.

## Monorepo Structure

This is a **Melos monorepo** (`melos.yaml` at root). Key packages under `packages/`:

- **`luciq_flutter`** — Main SDK plugin with native iOS (Objective-C) and Android (Java) implementations. This is where most development happens.
- **`luciq_dio_interceptor`** — Dio HTTP interceptor for network logging
- **`luciq_http_client`** — dart:io HttpClient integration for network logging
- **`luciq_flutter_modular`** — Integration with Flutter Modular router
- **`luciq_flutter_ndk`** — Native Development Kit integration

## Common Commands

```bash
# Bootstrap (first time / clean setup)
melos bootstrap

# Run all tests
melos test

# Run tests for a specific package
cd packages/luciq_flutter && flutter test

# Run a single test file
cd packages/luciq_flutter && flutter test test/crash_reporting_test.dart

# Static analysis
melos analyze

# Format code
melos format

# Regenerate Pigeon platform channel code
melos pigeon --no-select

# Regenerate build_runner code (mockito mocks, etc.)
melos generate --no-select

# Full init (cleans artifacts, bootstraps, generates all code)
./scripts/init.sh

# iOS pods
melos pods --no-select
```

## Architecture

### Platform Channel Layer (Pigeon)

The SDK communicates with native iOS/Android through **Pigeon**-generated platform channels. The flow is:

1. **Pigeon definitions**: `packages/luciq_flutter/pigeons/*.api.dart` — declare the API contracts
2. **Generated Dart**: `packages/luciq_flutter/lib/src/generated/*.api.g.dart`
3. **Generated iOS**: `packages/luciq_flutter/ios/Classes/Generated/` (Objective-C)
4. **Generated Android**: `packages/luciq_flutter/android/src/main/java/ai/luciq/flutter/generated/` (Java)

After modifying a `.api.dart` file in `pigeons/`, run `melos pigeon --no-select` to regenerate.

### Module Pattern

Each SDK feature is a static Dart class in `lib/src/modules/` (e.g., `APM`, `BugReporting`, `CrashReporting`, `Luciq`). These classes call through to the generated Pigeon host APIs to invoke native code. `Luciq` in `luciq.dart` is the main entry point for SDK initialization.

### Public API Surface

All public exports are defined in `packages/luciq_flutter/lib/luciq_flutter.dart`. This includes modules, models (in `lib/src/models/`), and utilities (in `lib/src/utils/`).

### Utilities

- **`luciq_navigator_observer.dart`** — Flutter NavigatorObserver for tracking route changes (repro steps)
- **`luciq_widget.dart`** — Widget wrapper for SDK screenshot/session replay
- **`private_views/`** — Widgets for auto-masking sensitive data in screenshots
- **`screen_loading/`** — Screen load time tracking with route matching
- **`user_steps/`** — User action tracking

## Testing

- Tests live in `packages/luciq_flutter/test/` (31+ test files)
- Uses **Mockito** for mocking — generated `.mocks.dart` files via `build_runner`
- After adding `@GenerateMocks` annotations, run `melos generate --no-select`
- E2E tests are in `/e2e/` (C# + Appium, separate from Flutter unit tests)

## Code Quality

- Linting: `analysis_options.yaml` extends `package:lint/analysis_options_package.yaml`
- Generated files (`*.g.dart`, `*.mocks.dart`) are excluded from analysis
- CI: CircleCI (see `.circleci/config.yml` for the current Flutter version)

## Output
- Answer is always line 1. Reasoning comes after, never before.
- No preamble. No "Great question!", "Sure!", "Of course!", "Certainly!", "Absolutely!".
- No hollow closings. No "I hope this helps!", "Let me know if you need anything!".
- No restating the prompt. If the task is clear, execute immediately.
- No explaining what you are about to do. Just do it.
- No unsolicited suggestions. Do exactly what was asked, nothing more.
- Structured output only: bullets, tables, code blocks. Prose only when explicitly requested.

## Token Efficiency
- Compress responses. Every sentence must earn its place.
- No redundant context. Do not repeat information already established in the session.
- No long intros or transitions between sections.
- Short responses are correct unless depth is explicitly requested.

## Typography - ASCII Only
- No em dashes (-) - use hyphens (-)
- No smart/curly quotes - use straight quotes (" ')
- No ellipsis character - use three dots (...)
- No Unicode bullets - use hyphens (-) or asterisks (*)
- No non-breaking spaces

## Sycophancy - Zero Tolerance
- Never validate the user before answering.
- Never say "You're absolutely right!" unless the user made a verifiable correct statement.
- Disagree when wrong. State the correction directly.
- Do not change a correct answer because the user pushes back.

## Accuracy and Speculation Control
- Never speculate about code, files, or APIs you have not read.
- If referencing a file or function: read it first, then answer.
- If unsure: say "I don't know." Never guess confidently.
- Never invent file paths, function names, or API signatures.
- If a user corrects a factual claim: accept it as ground truth for the entire session. Never re-assert the original claim.

## Code Output
- Return the simplest working solution. No over-engineering.
- No abstractions or helpers for single-use operations.
- No speculative features or future-proofing.
- No docstrings or comments on code that was not changed.
- Inline comments only where logic is non-obvious.
- Read the file before modifying it. Never edit blind.

## Warnings and Disclaimers
- No safety disclaimers unless there is a genuine life-safety or legal risk.
- No "Note that...", "Keep in mind that...", "It's worth mentioning..." soft warnings.
- No "As an AI, I..." framing.

## Session Memory
- Learn user corrections and preferences within the session.
- Apply them silently. Do not re-announce learned behavior.
- If the user corrects a mistake: fix it, remember it, move on.

## Scope Control
- Do not add features beyond what was asked.
- Do not refactor surrounding code when fixing a bug.
- Do not create new files unless strictly necessary.

## Override Rule
User instructions always override this file.
