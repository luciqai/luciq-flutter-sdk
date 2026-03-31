---
description: Scaffold a new SDK feature module following established patterns
---

# New Feature Module

Scaffold a new feature module in the Luciq Flutter SDK following established patterns.

## Parameters

- `name` (required): Feature name (e.g., `Surveys`, `FeatureRequests`)

## Steps

### 1. Plan the Module

- Determine the public API surface
- Identify required Pigeon platform channel methods
- List models needed

### 2. Create Pigeon API Definition

Create `packages/luciq_flutter/pigeons/<feature_name>.api.dart`:
- Define the host API (Dart -> Native) methods
- Define any Flutter API (Native -> Dart) callbacks
- Follow existing Pigeon patterns from other `.api.dart` files

### 3. Generate Platform Channel Code

```bash
melos pigeon --no-select
```

This generates:
- Dart: `lib/src/generated/<feature_name>.api.g.dart`
- iOS: `ios/Classes/Generated/`
- Android: `android/src/main/java/ai/luciq/flutter/generated/`

### 4. Create Module Class

Create `packages/luciq_flutter/lib/src/modules/<feature_name>.dart`:
- Static class following the pattern of existing modules (e.g., `BugReporting`, `APM`)
- Methods call through to generated Pigeon host API
- Add proper null checks and error handling

### 5. Create Models

Create any needed models in `packages/luciq_flutter/lib/src/models/`:
- Follow existing model patterns
- Include proper `enum` definitions

### 6. Export Public API

Update `packages/luciq_flutter/lib/luciq_flutter.dart`:
- Export the new module class
- Export any new models

### 7. Write Tests

Create `packages/luciq_flutter/test/<feature_name>_test.dart`:
- Mock the Pigeon host API using `@GenerateMocks`
- Run `melos generate --no-select` to generate mock files
- Test each public method
- Test error handling paths

### 8. Build and Test

```bash
cd packages/luciq_flutter
flutter test
melos analyze
```

## Checklist

- [ ] Pigeon API defined and generated
- [ ] Module class created with static methods
- [ ] Models created if needed
- [ ] Public exports updated
- [ ] Tests written and passing
- [ ] Analysis passes
