# Luciq Flutter SDK - Debug Logs

This document is the source of truth for the SDK's diagnostic log
output. It describes the canonical log shape, the vocabulary used to
trace a single call across layers, and how to enable the logs in your
host app.

## Enabling logs

Pass `debugLogsLevel` when initializing the SDK. The level is honored
by all three layers (Dart, iOS, Android) and gates every log emitted
through `LuciqLogger` / `LuciqFlutterLogger`.

```dart
Luciq.init(
  token: '<your-app-token>',
  invocationEvents: [...],
  debugLogsLevel: LogLevel.verbose, // or LogLevel.debug
);
```

Levels (most to least verbose):
- `verbose` - everything, including high-volume traces.
- `debug` - normal lifecycle (enter / exit / fire) plus all errors.
- `error` - errors only.
- `none` - silent.

To capture a debug trace mid-session (e.g. while reproducing a
support issue) without re-initializing the SDK, call
`Luciq.setDebugLogsLevel(LogLevel.debug)`. This affects the Dart side
only; the native log level is set at `init` time.

## Canonical log shape

Every diagnostic line emitted by the plugin follows one shape:

```
[<Feature>.<method>] (#<callId>)? phase=<enter|exit|error|fire> key=value ...
```

Fields:
- `Feature` - short module code matching the log tag (see table below).
- `method` - the public API method, including private helpers when
  relevant (e.g. `[BR.show]`, `[SUR.onShowSurvey]`).
- `callId` - 4-hex-char correlation id, present only for async /
  callback APIs. Echoed across Dart -> iOS / Android -> back so the
  full trace shares one token.
- `phase` - lifecycle marker:
  - `enter` - the API was called.
  - `exit`  - the API returned (success path). May carry
    `result` / `resultLength` / `resultCount` / `resultPresent`.
  - `warn`  - the API completed but with a recoverable degradation
    (request body truncated past the size limit, payload omitted by
    a user-supplied callback). Always followed by a `phase=exit` line
    on the same call - `warn` is informational, not terminal.
  - `error` - the API threw or set an error. Always carries
    `errorType` and (on Dart) a truncated `errorMessage`. A failing
    Pigeon-mapped enum validation closes the call on `error` - no
    matching `exit` follows.
  - `fire`  - a callback from native into Dart was invoked.
- `key=value` - additional context. Values follow these rules:
  - booleans: lowercase `true` / `false`.
  - strings: never logged raw - summarized as `<name>Length=N` or
    `<name>Present=true|false`.
  - lists / maps: summarized as `<name>Count=N`.
  - URLs: redacted via the platform helper before formatting.

## Correlation ids (`#callId`)

Correlation ids are 4-char lowercase hex tokens (`c7f3`, `00a1`, ...).
They are present only on APIs where matching a call to its outcome
needs more than the method name - i.e. async APIs with deferred
results and inbound callbacks from native.

### Dart-minted (call originates in Dart)

The Dart side mints the id via `CallId.next()` at the top of the call
and threads it through Pigeon into the native HostApi method. Both
sides log under the same id.

| Module    | Method                        |
|-----------|-------------------------------|
| Surveys   | `showSurvey`                  |
| Surveys   | `getAvailableSurveys`         |
| Surveys   | `hasRespondedToSurvey`        |
| Replies   | `show`                        |
| Replies   | `hasChats`                    |
| Replies   | `getUnreadRepliesCount`       |
| SessionReplay | `getSessionReplayLink`    |

### Native-minted (call originates in native, fires into Dart)

The native side mints the id (`[LuciqFlutterLogger nextCallId]` on
iOS, `LuciqFlutterLogger.nextCallId()` on Android) right before
invoking a `FlutterApi` callback. The id is passed through Pigeon to
Dart, which echoes it on the matching `phase=fire` log.

| Module        | Callback              |
|---------------|-----------------------|
| BugReporting  | `onSdkInvoke`         |
| BugReporting  | `onSdkDismiss`        |
| Surveys       | `onShowSurvey`        |
| Surveys       | `onDismissSurvey`     |
| Replies       | `onNewReply`          |
| PrivateView   | `capture`             |

Sync setters and getters of primitives are not correlated - their
method name plus tag is sufficient to disambiguate.

## Example traces

### Dart -> native success

A call to `Surveys.showSurvey('tok_abc')` produces:

```
LCQ-Flutter-SUR:         [SUR.showSurvey] #c7f3 phase=enter tokenPresent=true tokenLength=7
LCQ-Flutter-iOS-SUR:     [SUR.showSurvey] #c7f3 phase=enter tokenPresent=true tokenLength=7
LCQ-Flutter-iOS-SUR:     [SUR.showSurvey] #c7f3 phase=exit
LCQ-Flutter-SUR:         [SUR.showSurvey] #c7f3 phase=exit
```

Later, when the user dismisses the survey, the native side fires:

```
LCQ-Flutter-iOS-SUR:     [SUR.onDismissSurvey] #00a1 phase=fire
LCQ-Flutter-SUR:         [SUR.onDismissSurvey] #00a1 phase=fire callbackPresent=true
```

The two ids (`c7f3` for the show, `00a1` for the dismiss) are
independent.

### Async result

`Replies.getUnreadRepliesCount()` returning 3:

```
LCQ-Flutter-REP:         [REP.getUnreadRepliesCount] #1b2c phase=enter
LCQ-Flutter-Android-REP: [REP.getUnreadRepliesCount] #1b2c phase=enter
LCQ-Flutter-Android-REP: [REP.getUnreadRepliesCount] #1b2c phase=exit result=3
LCQ-Flutter-REP:         [REP.getUnreadRepliesCount] #1b2c phase=exit result=3
```

### Error path

Calling a method before `Luciq.init` (or any other native-side
failure) produces a `phase=error` line on whichever layer threw:

```
LCQ-Flutter-Android-SUR: [SUR.getAvailableSurveys] #2f9e phase=enter
LCQ-Flutter-Android-SUR: [SUR.getAvailableSurveys] #2f9e phase=error errorType=NullPointerException
LCQ-Flutter-SUR:         [SUR.getAvailableSurveys] #2f9e phase=error errorType=PlatformException errorMessage=PlatformException(error, ...)
```

Grepping any one of these lines for the call id (`#2f9e`) returns
the full lifecycle across both layers.

## Tag taxonomy

Each layer uses its own tag prefix so the layer is unambiguous from
the log line alone. Functional areas are kept identical across
layers.

| Feature code | Dart tag                 | iOS tag                         | Android tag                          |
|--------------|--------------------------|---------------------------------|--------------------------------------|
| Luciq        | `LCQ-Flutter-CORE:`      | `LCQ-Flutter-iOS-CORE:`         | `LCQ-Flutter-Android-CORE:`          |
| SCREEN       | `LCQ-Flutter-SCREEN:`    | `LCQ-Flutter-iOS-SCREEN:`       | `LCQ-Flutter-Android-SCREEN:`        |
| APM-SL       | `LCQ-Flutter-APM-SL:`    | `LCQ-Flutter-iOS-APM-SL:`       | `LCQ-Flutter-Android-APM-SL:`        |
| APM-SR       | `LCQ-Flutter-APM-SR:`    | `LCQ-Flutter-iOS-APM-SR:`       | `LCQ-Flutter-Android-APM-SR:`        |
| APM-UI       | `LCQ-Flutter-APM-UI:`    | `LCQ-Flutter-iOS-APM-UI:`       | `LCQ-Flutter-Android-APM-UI:`        |
| APM-LAUNCH   | `LCQ-Flutter-APM-LAUNCH:`| `LCQ-Flutter-iOS-APM-LAUNCH:`   | `LCQ-Flutter-Android-APM-LAUNCH:`    |
| APM-SPAN     | `LCQ-Flutter-APM-SPAN:`  | `LCQ-Flutter-iOS-APM-SPAN:`     | `LCQ-Flutter-Android-APM-SPAN:`      |
| APM-FLOW     | `LCQ-Flutter-APM-FLOW:`  | `LCQ-Flutter-iOS-APM-FLOW:`     | `LCQ-Flutter-Android-APM-FLOW:`      |
| APM-NET      | `LCQ-Flutter-APM-NET:`   | `LCQ-Flutter-iOS-APM-NET:`      | `LCQ-Flutter-Android-APM-NET:`       |
| BR           | `LCQ-Flutter-BR:`        | `LCQ-Flutter-iOS-BR:`           | `LCQ-Flutter-Android-BR:`            |
| CRASH        | `LCQ-Flutter-CRASH:`     | `LCQ-Flutter-iOS-CRASH:`        | `LCQ-Flutter-Android-CRASH:`         |
| SR           | `LCQ-Flutter-SR:`        | `LCQ-Flutter-iOS-SR:`           | `LCQ-Flutter-Android-SR:`            |
| PRIV         | `LCQ-Flutter-PRIV:`      | `LCQ-Flutter-iOS-PRIV:`         | `LCQ-Flutter-Android-PRIV:`          |
| FF           | `LCQ-Flutter-FF:`        | `LCQ-Flutter-iOS-FF:`           | `LCQ-Flutter-Android-FF:`            |
| NET          | `LCQ-Flutter-NET:`       | `LCQ-Flutter-iOS-NET:`          | `LCQ-Flutter-Android-NET:`           |
| SUR          | `LCQ-Flutter-SUR:`       | `LCQ-Flutter-iOS-SUR:`          | `LCQ-Flutter-Android-SUR:`           |
| REP          | `LCQ-Flutter-REP:`       | `LCQ-Flutter-iOS-REP:`          | `LCQ-Flutter-Android-REP:`           |
| FR           | `LCQ-Flutter-FR:`        | `LCQ-Flutter-iOS-FR:`           | `LCQ-Flutter-Android-FR:`            |
| STATE        | `LCQ-Flutter-STATE:`     | `LCQ-Flutter-iOS-STATE:`        | `LCQ-Flutter-Android-STATE:`         |
| LOG          | `LCQ-Flutter-LOG:`       | `LCQ-Flutter-iOS-LOG:`          | `LCQ-Flutter-Android-LOG:`           |

Tag constants live in:
- `lib/src/constants/debug_tags.dart`
- `ios/Classes/Util/LuciqFlutterDebugTags.{h,m}`
- `android/src/main/java/ai/luciq/flutter/util/LuciqFlutterDebugTags.java`

## Privacy

Logs never include raw user payloads (tokens, urls, log message
bodies, file paths, user attributes, screen names). The plugin
exposes redaction helpers:
- Dart: `redactUrlForLog` in `lib/src/utils/luciq_utils.dart`.
- iOS:  `+[LuciqFlutterLogger redactURL:]`.
- Android: `LuciqFlutterLogger.redactUrl(...)`.

When adding new logs, summarize: `Length`, `Count`, `Present`.

## Common debugging recipes

### Find every line for one call

```
adb logcat | grep '#c7f3'
flutter logs | grep '#c7f3'
```

### Find all errors from one feature

```
adb logcat -s LCQ-Flutter-Android-SUR | grep 'phase=error'
```

### Watch every async/callback API across layers

```
adb logcat | grep -E 'phase=(enter|exit|warn|error|fire)'
```

### Check that native exceptions are surfacing

Prior to this refit, native SDK exceptions were silently swallowed
via `e.printStackTrace()` on Android. They are now logged with
`phase=error errorType=<ClassName>`. To verify in your own build:

```
adb logcat | grep 'LCQ-Flutter-Android-' | grep 'phase=error'
```

## For AI assistants parsing these logs

- The bracketed `[Feature.method]` token is stable and greppable.
- The `#<callId>` token, when present, is unique within the live
  process for the originating call - join on it to reconstruct a
  trace.
- `phase` is a closed vocabulary: `enter`, `exit`, `warn`, `error`,
  `fire`. `warn` is informational and is always followed by `exit`
  on the same call; `error` is terminal and is not followed by `exit`.
- `errorType` is always the runtime class name; `errorMessage` is
  truncated to 256 chars with a trailing `...` when longer.
- Tag layer prefix (`LCQ-Flutter-`, `LCQ-Flutter-iOS-`,
  `LCQ-Flutter-Android-`) identifies the emitting layer.
- A `phase=fire` line on the Dart side is always preceded by a
  `phase=fire` line on the native side with the same `#callId`.
- A `phase=error` line is not necessarily followed by a Dart-side
  `phase=error`: if the native error is recoverable (e.g. a parsed
  validation failure), Dart may not see it. Always check the layer
  prefix.
