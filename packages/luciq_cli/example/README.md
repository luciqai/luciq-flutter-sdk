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

