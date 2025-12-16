# Luciq CLI

A command-line interface for Luciq Flutter SDK.

## Installation

### Global Installation

```bash
dart pub global activate luciq_cli
```

### Local Development

```bash
cd packages/luciq_cli
dart pub get
```

## Usage

### Migration Command

Migrate your Flutter project from Instabug to Luciq:

```bash
# Run migration on current Flutter project directory
luciq migrate

# Run migration on specific Flutter project path
luciq migrate --project-path /path/to/flutter/project

# Dry run to see what would be changed
luciq migrate --dry-run

# Get help
luciq migrate --help
```

### Upload Symbols Command

Upload debug symbol files to Luciq. The command automatically detects platform from filenames:
- Files containing `.android` in their name → uploaded as Android platform
- Files containing `.ios` in their name → uploaded as iOS platform

```bash
# Upload all symbols (searches current directory recursively if --symbols-path not provided)
luciq upload-symbols

# Upload symbols from a specific directory
luciq upload-symbols --symbols-path /path/to/symbols

# Upload symbols with explicit credentials
luciq upload-symbols --token YOUR_APP_TOKEN --api_key YOUR_API_KEY

# Upload symbols with native sourcemaps (Android mapping.txt and iOS DWARF files)
luciq upload-symbols --enable-native-sourcemaps

# Upload symbols with explicit version (overrides pubspec.yaml)
luciq upload-symbols --version-name "1.0.0" --version-number "1"

# Upload symbols with verbose logging
luciq upload-symbols --verbose-logs

# Get help
luciq upload-symbols --help
```

**Example:**
If your symbols folder contains:
- `app.android-arm.symbols`
- `app.android-arm64.symbols`
- `app.ios-arm64.symbols`

The command will:
1. Create one zip file with all `.android` files and upload as Android platform
2. Create another zip file with all `.ios` files and upload as iOS platform

**Note:** The command automatically:
- Finds the app token from your source files (luciq.json, Dart files, .env files, or JS/TS files) if not provided
- Reads the app version from `pubspec.yaml` (can be overridden with `--version-name` and `--version-number`)
- Groups files by platform based on filename (`.android` or `.ios`)
- Uploads each platform group separately
- If `--symbols-path` is not provided, searches the current directory recursively for `.symbols` files (skips common build/dependency directories like `build`, `.git`, `node_modules`, etc.)

**Native Sourcemaps (`--enable-native-sourcemaps`):**
When enabled, the command also uploads:
- **Android**: `mapping.txt` file from `build/*/outputs/mapping/release/mapping.txt` to the native sourcemaps endpoint
- **iOS**: DWARF files from `build/ios/archive/*/dSYMs/*.framework.dSYM/Contents/Resources/DWARF/` or `ios/build/archive/...` (zipped and uploaded to the native sourcemaps endpoint)

**Environment Variables:**
- `LUCIQ_APP_TOKEN` or `INSTABUG_APP_TOKEN` - Your app token
- `LUCIQ_API_KEY` or `INSTABUG_API_KEY` - Your API key
- `LUCIQ_AUTO_UPLOAD_ENABLE` or `INSTABUG_AUTO_UPLOAD_ENABLE` - Enable/disable auto upload (default: true)

You can also set these in `local.properties` file:
```properties
LUCIQ_APP_TOKEN=your_token_here
LUCIQ_API_KEY=your_api_key_here
LUCIQ_AUTO_UPLOAD_ENABLE=true
```

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

