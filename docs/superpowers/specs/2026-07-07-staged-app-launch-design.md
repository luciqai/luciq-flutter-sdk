# Staged Cold App Launch Capture - Design

Date: 2026-07-07
Revised: 2026-07-08 (gating moved native-side; binding/ordering caveats)
Branch: feat/app-launch-stages
Status: Approved for implementation planning

## Problem

Today the Luciq Flutter SDK reports app launch as a single bulk duration. The
duration is measured entirely inside the native binaries (iOS
`LuciqSDK.xcframework` / `IBGAppLaunchTracker`, Android `luciq-apm` aar /
`ai.luciq.apm.APM`). The Flutter layer is a thin Pigeon bridge that forwards
only two things:

- `APM.setColdAppLaunchEnabled(bool)` - toggles native cold-launch capture.
- `APM.endAppLaunch()` - zero-payload signal that the launch is interactive.

Flutter never sees a start timestamp or the computed duration. We want to
replace the single bulk duration with a breakdown of launch stages, each with
its own duration.

## Goal

Capture a cold app launch as 3 stages with individual durations, measured on
the Flutter side and reported to native over a new Pigeon method, without
changing the public `endAppLaunch()` contract.

## Decisions (locked)

- Stage source: Flutter measures the boundaries it can observe and reports
  them; native keeps the process-start anchor it already owns.
- Stage model: auto-detected only (no host instrumentation beyond the existing
  `endAppLaunch()` trigger).
- Stage count: 3 stages.
- Launch types: cold only. Warm/hot are out of scope.
- Gating: no Flutter-side gating. Flutter always captures timestamps and
  reports stages; native discards the staged report when cold launch capture
  is disabled. Rationale: `ApmHostApi` exposes only the setter
  `setColdAppLaunchEnabled` (no getter), and an async enabled check cannot
  gate the synchronous T1 capture at the top of `Luciq.init` anyway.
- Pigeon contract: primitive args (no data class), mirroring
  `reportScreenLoadingCP`.
- Native receiving API + backend schema: built in parallel against the agreed
  contract; the Flutter side is buildable and testable against mocks now.

## The 3 stages and clocks

Timeline of a cold launch:

```
process     Luciq.init()   first frame   endAppLaunch()
start (T0)   (T1)          rendered (T2)  interactive (T3)
  |------------|-------------|-------------|
   Stage 1        Stage 2       Stage 3
  Native init   Flutter        Time-to-
  (pre-Dart)    render         interactive
```

| Stage | Window   | Boundary source                                        |
|-------|----------|--------------------------------------------------------|
| 1     | T0 -> T1 | T0 = native process start (already owned); T1 = `Luciq.init` call |
| 2     | T1 -> T2 | T2 = first `WidgetsBinding.instance.addPostFrameCallback` |
| 3     | T2 -> T3 | T3 = host calls `APM.endAppLaunch()`                   |

Clock model mirrors screen loading (see
`lib/src/utils/screen_loading/luciq_capture_screen_loading.dart` lines 64-67
and 101-105):

- `LCQDateTime.I.now().microsecondsSinceEpoch` - wall-clock epoch micros. Used
  as the single anchor native aligns to (matches how `reportScreenLoadingCP`
  passes `startTimeInMicroseconds`).
- `LuciqMonotonicClock.I.now` (`Timeline.now`) - monotonic micros. Used to
  compute drift-free stage durations.

Flutter knows T1, T2, T3. It does not know T0 (process start is native). So:

- Stage 1 duration is computed by native as `T1_epoch - T0_epoch`. Flutter
  supplies `T1_epoch` (`dartEntryMicros`).
- Stage 2 duration = monotonic(T2) - monotonic(T1), computed by Flutter.
- Stage 3 duration = monotonic(T3) - monotonic(T2), computed by Flutter.
- Bulk total remains derivable: `stage1 + stage2 + stage3`.

Both clock singletons are mockable test seams (`LCQDateTime.setInstance`,
`LuciqMonotonicClock.setInstance`).

Caveat to document: T1 is anchored at the `Luciq.init` call, so Stage 1
("native init") includes native process start + engine boot + Dart VM +
whatever host `main()` work runs before `Luciq.init`. If the host calls
`Luciq.init` late, Stage 1 grows accordingly. This is inherent to Flutter-side
measurement and will be noted in the public docs.

## Architecture

New `AppLaunchManager` singleton, following the established manager pattern
(`ScreenLoadingManager.I`, `CustomSpanManager.I`):

- Location: `lib/src/utils/app_launch/app_launch_manager.dart`.
- Singleton with `instance` / `I` accessors and a
  `@visibleForTesting setInstance` seam.
- Holds a `$setHostApi(ApmHostApi)` seam, wired from `APM.$setHostApi`
  (`lib/src/modules/apm.dart` line 28) the same way `CustomSpanManager` is.
- Responsibilities:
    - `markDartEntry()` - captures T1 (epoch + monotonic). Called once in
      `Luciq.init` (`lib/src/modules/luciq.dart` line 217), immediately after
      `$setup()` (which wires the host APIs), before the async host call.
    - registers a one-shot post-frame callback via the null-aware
      `WidgetsBinding.instance?.addPostFrameCallback` (same guard as
      `luciq_capture_screen_loading.dart` line 101) to capture T2 monotonic and
      compute Stage 2 duration. If the binding is not initialized when
      `Luciq.init` runs (host called it before
      `WidgetsFlutterBinding.ensureInitialized()`), T2 is never captured and
      the launch degrades to bulk-only.
  - `reportStagesOnEndAppLaunch()` - on `endAppLaunch()`, captures T3, computes
    Stage 3 duration, and calls the new host method, then the existing
    `endAppLaunch()`.

Rationale for a dedicated manager (not inline in `APM`): launch-start state
must be captured before the SDK is fully built and must survive between
`Luciq.init` and `endAppLaunch()`. This is the same reason `CustomSpanManager`
and `ScreenLoadingManager` are singletons rather than static passthroughs.

## Pigeon contract

Add one internal `@HostApi` method to `ApmHostApi` in
`pigeons/apm.api.dart` (after the existing screen-loading methods):

```dart
void reportAppLaunchStages(
  int dartEntryMicros,           // T1 epoch anchor; native computes stage 1 vs T0
  int uiRenderDurationMicros,    // stage 2 duration, monotonic
  int interactiveDurationMicros, // stage 3 duration, monotonic
);
```

Regenerate all bindings with `melos pigeon --no-select` (never hand-edit
generated files):

- Dart: `lib/src/generated/apm.api.g.dart`
- iOS: `ios/Classes/Generated/ApmPigeon.{h,m}`
- Android: `android/src/main/java/ai/luciq/flutter/generated/ApmPigeon.java`

The public `APM.endAppLaunch()` signature does not change. Staging is additive.

## Dart module surface

In `lib/src/modules/apm.dart`:

- Add an internal `reportAppLaunchStages(...)` wrapper following the
  `reportScreenLoadingCP` shape (lines 409-428): `hostCall` +
  `DebugTags.apmAppLaunch`, `@internal`.
- `endAppLaunch()` (line 309) delegates to
  `AppLaunchManager.I.reportStagesOnEndAppLaunch()`, which reports the stages
  (when available) and then invokes the existing `_host.endAppLaunch()`.
- Wire `AppLaunchManager.I.$setHostApi(host)` inside `APM.$setHostApi`
  (line 28), next to the existing `CustomSpanManager.I.$setHostApi(host)`.

No new public export is strictly required (the manager and the report method
are internal). `endAppLaunch` and `setColdAppLaunchEnabled` remain the public
surface. Barrel `lib/luciq_flutter.dart` only changes if we choose to expose a
launch-stage enum later (not in this scope).

## Data flow

1. Host calls `Luciq.init(...)`. Right after `$setup()`,
   `AppLaunchManager.I.markDartEntry()` -> stores T1 epoch + T1 monotonic and
   registers the one-shot post-frame callback (null-aware; skipped if the
   binding is not initialized).
2. First frame renders -> post-frame callback fires -> store T2 monotonic ->
   Stage 2 duration = T2mono - T1mono.
3. Host calls `APM.endAppLaunch()` -> `AppLaunchManager` captures T3 monotonic
   -> Stage 3 duration = T3mono - T2mono -> if all boundaries present, call
   `APM.reportAppLaunchStages(T1epoch, stage2Dur, stage3Dur)` -> then existing
   `_host.endAppLaunch()`.
4. Native computes Stage 1 (`T1epoch - T0epoch`), persists the 3 stage
   durations, reports to backend.

## Error handling and graceful degradation

- `endAppLaunch()` fired before the first frame (T2 missing): skip the staged
  report; native falls back to today's single bulk duration.
- `Luciq.init` called before `WidgetsFlutterBinding.ensureInitialized()`
  (binding not initialized): post-frame callback is skipped via the null-aware
  call, T2 is never captured, staged report is skipped. Bulk-only.
- Host never calls `endAppLaunch()`: native auto-ends as today; no staged data
  sent. Bulk-only.
- Cold launch capture disabled (`setColdAppLaunchEnabled(false)`) or feature
  flag off: Flutter still captures timestamps (cheap) and sends the staged
  report; native discards it. No Flutter-side gating - see Gating.
- `markDartEntry()` called more than once (hot restart, re-init): only the
  first launch window is tracked; subsequent calls are ignored/logged.
- All host calls go through `hostCall` (never throw into the host app) and log
  with `DebugTags.apmAppLaunch` using the `phase=enter/exit/error` convention.

## Gating

Decision: gating is native-side only. No Flutter-side gating.

- Flutter cannot read the cold-launch enabled state: `ApmHostApi` exposes only
  the setter `setColdAppLaunchEnabled` (`pigeons/apm.api.dart` line 11) - no
  getter - and `FlagsConfig` has no appLaunch entry.
- Even with a getter, an async enabled check could not gate the synchronous
  T1 capture / callback registration at the top of `Luciq.init` (the SDK is
  not built yet at that point).
- So: Flutter always captures timestamps and always sends
  `reportAppLaunchStages` on `endAppLaunch()` (when boundaries are present).
  Native discards the staged report when cold launch capture is disabled or
  the feature flag is off - the same place it already gates the bulk
  duration.
- No new Pigeon getter, no `FlagsConfig.appLaunch`, no new remote flag on the
  Flutter side.

## Testing

- Unit: new `test/utils/app_launch/app_launch_manager_test.dart`. Inject mock
  `LCQDateTime`, `LuciqMonotonicClock`, and `ApmHostApi`. Drive the post-frame
  callback and `endAppLaunch()`; assert the exact
  `reportAppLaunchStages(dartEntryMicros, uiRenderDurationMicros,
  interactiveDurationMicros)` arguments.
- Edge cases: endAppLaunch before first frame (no report), binding not
  initialized at markDartEntry (no T2, no report), double markDartEntry
  (single window). No disabled-toggle test on the Flutter side - gating is
  native-only.
- Extend `test/apm_test.dart` for the new `APM.reportAppLaunchStages` host
  passthrough and the `endAppLaunch` -> manager delegation.
- Mockito with `@GenerateMocks`; run `melos generate --no-select` after adding
  annotations. Run `melos analyze` and `melos format`.

## External dependencies (not in this repo)

1. Native receiving API - the load-bearing dependency. Neither platform
   exposes a staged launch API today (`endAppLaunch` is arg-less on both;
   Android record model stores a single duration long). The staged API must
   also own gating: discard the staged report when cold launch capture is
   disabled or the feature flag is off (Flutter sends unconditionally).
   - iOS: `ios/Classes/Modules/ApmApi.m` implements the generated selector and
     calls a new `LCQAPM` staged API. Timestamps as microseconds
     (`LCQMicroSecondsTimeInterval`), matching `startCpUiTrace` /
     `reportScreenLoadingCP`.
   - Android: `android/src/main/java/ai/luciq/flutter/modules/ApmApi.java`
     adds the `@Override`, try/catch + log, delegating to a new
     `ai.luciq.apm.APM` staged API.
2. Backend/dashboard - must ingest and display the 3 stage durations. No schema
   exists in this repo; the exact field names/units are aligned with the native
   and backend teams. The Flutter contract (`dartEntryMicros`,
   `uiRenderDurationMicros`, `interactiveDurationMicros`) is the coordination
   point.

## Out of scope

- Warm and hot launch staging (and bridging their enable toggles).
- Custom/host-defined launch stages.
- Changing how native measures the process-start anchor or the bulk duration.
- Version bump and CHANGELOG entry (owned by the release manager on master).

## Key files

To change:

- `pigeons/apm.api.dart` - add `reportAppLaunchStages`.
- `lib/src/modules/apm.dart` - internal `reportAppLaunchStages` wrapper;
  `endAppLaunch` delegation; `$setHostApi` wiring.
- `lib/src/modules/luciq.dart` - call `AppLaunchManager.I.markDartEntry()` in
  `init` (line 217).
- `lib/src/utils/app_launch/app_launch_manager.dart` - new manager (create).
- Tests as above.

Regenerated (do not hand-edit): `lib/src/generated/apm.api.g.dart`,
`ios/Classes/Generated/ApmPigeon.{h,m}`,
`android/.../generated/ApmPigeon.java`.

Native bridge stubs (this repo, delegate to future native API):
`ios/Classes/Modules/ApmApi.m`, `android/.../modules/ApmApi.java`.

Reference precedents: `lib/src/utils/screen_loading/screen_loading_manager.dart`,
`lib/src/utils/screen_loading/luciq_capture_screen_loading.dart`,
`lib/src/utils/custom_span/custom_span_manager.dart`.
