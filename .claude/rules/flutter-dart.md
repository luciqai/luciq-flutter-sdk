# Flutter/Dart rules for this SDK

Project-specific conventions only. Generic Flutter/Dart best practice (theming,
colors, fonts, layout, routing, accessibility, state management) is already
part of Claude's training and is not repeated here.

## Scope note

This repo is an SDK (a Flutter plugin + companion packages), not an end-user
app. Rules about app-layer concerns (navigation, theming, responsive UI,
state management patterns) do not apply.

## Dart style

* Follow Effective Dart (https://dart.dev/effective-dart).
* Line length: 80 chars.
* `PascalCase` for classes, `camelCase` for members/variables/functions,
  `snake_case` for files.
* Sound null safety. Avoid `!` unless the value is provably non-null.
* Prefer arrow syntax for one-line functions.
* Prefer exhaustive `switch` expressions/statements.
* Keep functions short and single-purpose (aim for < 20 lines).

## Documentation

* Use `///` doc comments on public APIs (classes, constructors, methods,
  top-level functions).
* First sentence is a concise, user-centric summary ending in a period.
* Document the _why_, not the _what_. Don't restate what the name already
  conveys.
* Don't add trailing comments.

## Module pattern (this repo)

Each SDK feature is a static Dart class in
`packages/luciq_flutter/lib/src/modules/` (e.g. `APM`, `BugReporting`,
`CrashReporting`, `Luciq`). These classes call through to the Pigeon-generated
host APIs to invoke native code. `Luciq` in `luciq.dart` is the main entry
point for SDK initialization.

## Platform channels (Pigeon)

* API contracts live in `packages/luciq_flutter/pigeons/*.api.dart`.
* After changing a `.api.dart` file, run `melos pigeon --no-select` to
  regenerate Dart/Obj-C/Java bindings.
* Do not hand-edit generated files under `lib/src/generated/`,
  `ios/Classes/Generated/`, or `android/.../generated/`.

## Public API surface

* All public exports are declared in
  `packages/luciq_flutter/lib/luciq_flutter.dart`.
* When adding a new public API, export it from that barrel file.

## Error handling

* Anticipate platform exceptions from platform channel calls.
* Never let SDK code throw into the host app.
* Log with `dart:developer`'s `log`, not `print`.

## Testing

* Tests live in `packages/luciq_flutter/test/`.
* Use **Mockito** (`@GenerateMocks`). After adding annotations, run
  `melos generate --no-select` to regenerate `*.mocks.dart`.
* Follow Arrange-Act-Assert.
* Prefer fakes over mocks when the contract is small.
* E2E tests (C# + Appium) live under `/e2e/` and are out of scope for unit
  test runs.

## Code generation

* `build_runner` is the generator. Run via
  `melos generate --no-select` (wraps `dart run build_runner build --delete-conflicting-outputs`).
* Generated files (`*.g.dart`, `*.mocks.dart`) are excluded from analysis.

## Package management

* Use `flutter pub add <pkg>` (dep), `flutter pub add dev:<pkg>` (dev dep),
  `flutter pub add override:<pkg>:<ver>` (override), `dart pub remove <pkg>`.
* Prefer zero new dependencies unless the feature genuinely requires one.

## Lint / format

* Linting config: `analysis_options.yaml` extends
  `package:lint/analysis_options_package.yaml`.
* Run `melos analyze` for analysis and `melos format` for formatting across
  all packages.
