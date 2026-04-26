# Luciq for Flutter

[![pub package](https://img.shields.io/pub/v/luciq_flutter.svg)](https://pub.dev/packages/luciq_flutter)

A Flutter plugin for [Luciq](https://luciq.ai/).

## Available Features

|      Feature                                              | Status  |
|:---------------------------------------------------------:|:-------:|
| [Bug Reporting](https://docs.luciq.ai/docs/flutter-bug-reporting)               |    ✅   |
| [Crash Reporting](https://docs.luciq.ai/docs/flutter-crash-reporting)           |    ✅   |
| [App Performance Monitoring](https://docs.luciq.ai/docs/flutter-apm)            |    ✅   |
| [In-App Replies](https://docs.luciq.ai/docs/flutter-in-app-replies)             |    ✅   |
| [In-App Surveys](https://docs.luciq.ai/docs/flutter-in-app-surveys)             |    ✅   |
| [Feature Requests](https://docs.luciq.ai/docs/flutter-in-app-feature-requests)  |    ✅   |

* ✅ Stable
* ⚙️ Under active development

## Integration

### Installation

1. Add Luciq to your `pubspec.yaml` file.

```yaml
dependencies:
      luciq_flutter:
```

2. Install the package by running the following command.

```bash
flutter packages get
```

### Initializing Luciq

Initialize the SDK in your `main` function with the `appRunner` callback. This starts the SDK and
automatically sets up crash reporting by installing error handlers and wrapping your app in a
guarded zone.

```dart
import 'package:luciq_flutter/luciq_flutter.dart';

void main() {
  Luciq.init(
    token: 'APP_TOKEN',
    invocationEvents: [InvocationEvent.shake],
    appRunner: () => runApp(MyApp()),
  );
}
```

## Crash reporting

When you use the `appRunner` parameter, Luciq automatically installs `FlutterError.onError`,
`PlatformDispatcher.onError`, and `runZonedGuarded` error handlers. Every unhandled crash in your
app is captured and sent to the crashes page of your dashboard.

⚠️ **Crashes will only be reported in release mode and not in debug mode.**

### Advanced: Manual Error Handler Setup

If you need custom error handling logic, you can skip `appRunner` and set up error handlers
manually:

```dart
void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      Luciq.init(
        token: 'APP_TOKEN',
        invocationEvents: [InvocationEvent.shake],
      );

      FlutterError.onError = (FlutterErrorDetails details) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      };

      runApp(MyApp());
    },
    CrashReporting.reportCrash,
  );
}
```

## Repro Steps
Repro Steps list all of the actions an app user took before reporting a bug or crash, grouped by the screens they visited in your app.
 
 To enable this feature, you need to add `LuciqNavigatorObserver` to the `navigatorObservers` :
 ```
  runApp(MaterialApp(
    navigatorObservers: [LuciqNavigatorObserver()],
  ));
  ```

## Network Logging
You can choose to attach all your network requests to the reports being sent to the dashboard. To enable the feature when using the `dart:io` package `HttpClient`, please refer to the [Luciq Dart IO Http Client](https://github.com/Luciq/luciq-dart-io-http-client) repository.

We also support the packages `http` and `dio`. For details on how to enable network logging for these external packages, refer to the [Luciq Dart Http Adapter](https://github.com/Luciq/Luciq-Dart-http-Adapter) and the [Luciq Dio Interceptor](https://github.com/Luciq/Luciq-Dio-Interceptor) repositories.

## Microphone and Photo Library Usage Description (iOS Only)

Luciq needs access to the microphone and photo library to be able to let users add audio and video attachments. Starting from iOS 10, apps that don’t provide a usage description for those 2 permissions would be rejected when submitted to the App Store.

For your app not to be rejected, you’ll need to add the following 2 keys to your app’s info.plist file with text explaining to the user why those permissions are needed:

* `NSMicrophoneUsageDescription`
* `NSPhotoLibraryUsageDescription`

If your app doesn’t already access the microphone or photo library, we recommend using a usage description like:

* "`<app name>` needs access to the microphone to be able to attach voice notes."
* "`<app name>` needs access to your photo library for you to be able to attach images."

**The permission alert for accessing the microphone/photo library will NOT appear unless users attempt to attach a voice note/photo while using Luciq.**
