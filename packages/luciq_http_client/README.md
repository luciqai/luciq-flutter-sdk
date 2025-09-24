# luciq_http_client

A dart package to support Luciq network logging for the external dart [http](https://pub.dev/packages/http) package.

## Getting Started

You can choose to attach all your network requests data to the Luciq reports being sent to the dashboard. See the details below on how to enable the feature for the `http` package.

### Installation

1. Add the dependency to your project `pubspec.yml`:

```yaml
dependencies:
  luciq_http_client:
```

2. Install the package by running the following command.

```bash
flutter packages get
```

### Usage

To enable logging, use the custom http client provided by Luciq:

```dart
final client = LuciqHttpClient();
```

Then proceed to use the package normally:

```dart
final response = await client.get(Uri.parse(URL));
```
