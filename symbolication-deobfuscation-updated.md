---
description: >-
  Explained here is how to symbolicate your crashes to get more details from the
  stack trace for your Flutter apps.
---

# Symbolication/Deobfuscation

### Deobfuscating Dart Crashes

In order to start deobfuscating Dart related crashes, you'll first need to follow the steps in the following URL to obfuscate your app: https://docs.flutter.dev/deployment/obfuscate

#### Uploading Symbol Files with Luciq CLI

The easiest way to upload symbol files for both Android and iOS is to use the Luciq CLI tool.

{% stepper %}
{% step %}
#### Install Luciq CLI

Install the Luciq CLI globally using Dart:

{% code title="Terminal" %}
```bash
dart pub global activate luciq_cli
```
{% endcode %}

Make sure the Dart global bin directory is in your PATH. If not, add it:

{% code title="Terminal" %}
```bash
# For macOS/Linux
export PATH="$PATH":"$HOME/.pub-cache/bin"

# For Windows
set PATH=%PATH%;%LOCALAPPDATA%\Pub\Cache\bin
```
{% endcode %}
{% endstep %}

{% step %}
#### Set up your credentials

You can provide your credentials in multiple ways:

**Option 1: Environment Variables**
{% code title="Terminal" %}
```bash
export LUCIQ_APP_TOKEN=your_app_token_here
export LUCIQ_API_KEY=your_api_key_here
```
{% endcode %}

**Option 2: local.properties file**
Create a `local.properties` file in your project root:
{% code title="local.properties" %}
```properties
LUCIQ_APP_TOKEN=your_app_token_here
LUCIQ_API_KEY=your_api_key_here
```
{% endcode %}

**Option 3: Pass as command-line arguments** (shown in next step)

{% hint style="info" %}
Reach out to our support team to get your `API_KEY` if you don't have one.
{% endhint %}
{% endstep %}

{% step %}
#### Upload symbol files

Run the upload command from your Flutter project directory:

{% code title="Terminal" %}
```bash
# Upload all symbols (searches current directory recursively)
luciq upload-symbols

# Upload from a specific directory
luciq upload-symbols --symbols-path /path/to/symbols

# Upload with explicit credentials
luciq upload-symbols --token YOUR_APP_TOKEN --api_key YOUR_API_KEY

# Upload with native sourcemaps (includes Android mapping.txt and iOS DWARF files)
luciq upload-symbols --enable-native-sourcemaps

# Upload with verbose logging to see detailed progress
luciq upload-symbols --verbose-logs
```
{% endcode %}

The CLI will automatically:
- Detect platform from filenames (`.android` or `.ios`)
- Read app version from `pubspec.yaml`
- Group and upload files by platform
- Find your app token from source files if not provided

{% hint style="tip" %}
For more options and advanced usage, run `luciq upload-symbols --help`
{% endhint %}
{% endstep %}
{% endstepper %}

#### How Symbol File Upload Works

The Luciq CLI automatically detects and groups your symbol files:

- Files containing `.android` in their name are uploaded to the Android endpoint
- Files containing `.ios` in their name are uploaded to the iOS endpoint

**Example:**
If your symbols folder contains:
- `app.android-arm.symbols`
- `app.android-arm64.symbols`
- `app.ios-arm64.symbols`

The CLI will:
1. Create one zip with all `.android` files → upload as Android platform
2. Create another zip with all `.ios` files → upload as iOS platform

#### Manual Upload Using API

If you prefer to upload symbol files manually using the API, you can use the following endpoints:

{% hint style="warning" %}
**Important:** When uploading via API, symbol files must be packaged as a ZIP file with all symbol files in the root directory (no subfolders). The archive must be a `.zip` file format.
{% endhint %}

##### Android Symbol Upload

{% stepper %}
{% step %}
#### Fetch the symbol file

Obtain the symbol file for your Android build and create a ZIP file containing all symbol files in the root directory (without any subfolders).

{% hint style="info" %}
Example structure:
```
symbols.zip
├── app.android-arm.symbols
├── app.android-arm64.symbols
└── app.android-x86.symbols
```
Do NOT include folders inside the ZIP.
{% endhint %}
{% endstep %}

{% step %}
#### Get your API\_KEY

Reach out to our support team to get your `API_KEY`.
{% endstep %}

{% step %}
#### Upload the mapping file

Upload the mapping file using the following endpoint:

{% code title="cURL" %}
```bash
curl --location --request POST 'https://api.instabug.com/api/web/public/flutter-symbol-files/android' \
--header 'Accept: */*' \
--header 'Content-Type: multipart/form-data' \
--header 'Accept-Encoding: gzip, deflate, br' \
--form 'file=@"/path/to/symbols.zip"' \
--form 'application_token="YOUR_APP_TOKEN"' \
--form 'api_key="YOUR_API_KEY"' \
--form 'app_version_name="1.0.0"' \
--form 'app_version_code="1"'
```
{% endcode %}

**Parameters:**
- `file`: Path to your symbols ZIP file
- `application_token`: Your Luciq application token
- `api_key`: Your API key
- `app_version_name`: Your app version (e.g., "1.0.0")
- `app_version_code`: Your app build number (e.g., "1")

{% endstep %}
{% endstepper %}

##### iOS Symbol Upload

{% stepper %}
{% step %}
#### Fetch the symbol file

Obtain the symbol file for your iOS build and create a ZIP file containing all symbol files in the root directory (without any subfolders).

{% hint style="info" %}
Example structure:
```
symbols.zip
├── app.ios-arm64.symbols
└── app.ios-x86_64.symbols
```
Do NOT include folders inside the ZIP.
{% endhint %}
{% endstep %}

{% step %}
#### Get your API\_KEY

Reach out to our support team to get your `API_KEY`.
{% endstep %}

{% step %}
#### Upload the mapping file

Upload the mapping file using the following endpoint:

{% code title="cURL" %}
```bash
curl --location --request POST 'https://api.instabug.com/api/web/public/flutter-symbol-files/ios' \
--header 'Accept: */*' \
--header 'Content-Type: multipart/form-data' \
--header 'Accept-Encoding: gzip, deflate, br' \
--form 'file=@"/path/to/symbols.zip"' \
--form 'application_token="YOUR_APP_TOKEN"' \
--form 'api_key="YOUR_API_KEY"' \
--form 'app_version_name="1.0.0"' \
--form 'app_version_code="1"'
```
{% endcode %}

**Parameters:**
- `file`: Path to your symbols ZIP file
- `application_token`: Your Luciq application token
- `api_key`: Your API key
- `app_version_name`: Your app version (e.g., "1.0.0")
- `app_version_code`: Your app build number (e.g., "1")
{% endstep %}
{% endstepper %}

#### Native Crash Symbolication

For native iOS and Android crashes, you'll need to upload additional symbol files.

{% stepper %}
{% step %}
#### iOS Native Symbolication

For iOS native crashes and dSYM symbolication, follow the iOS documentation:

{% embed url="https://docs.luciq.ai/ios/setup-luciq-for-ios/setup-crash-reporting/symbolication" %}
iOS Symbolication Guide
{% endembed %}

{% hint style="tip" %}
You can also use the `--enable-native-sourcemaps` flag with the Luciq CLI to automatically upload iOS DWARF files.
{% endhint %}
{% endstep %}

{% step %}
#### Android Native Deobfuscation

For Android native crashes and ProGuard/R8 mapping files, follow the Android documentation:

{% embed url="https://docs.luciq.ai/android/set-up-luciq-for-android/set-up-crash-reporting/deobfuscation-for-android" %}
Android Deobfuscation Guide
{% endembed %}

{% hint style="tip" %}
You can also use the `--enable-native-sourcemaps` flag with the Luciq CLI to automatically upload the Android mapping.txt file.
{% endhint %}
{% endstep %}
{% endstepper %}
