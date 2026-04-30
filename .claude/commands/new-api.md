---
description: Add a new public API method to an existing SDK feature
---

# New API Method

Add a new public API method to an existing feature module.

## Parameters

- `module` (required): Target module (e.g., `BugReporting`, `APM`, `CrashReporting`, `Luciq`)
- `method` (required): Method name and signature description

## Steps

### 1. Define API Contract

Add the method to the Pigeon definition in `packages/luciq_flutter/pigeons/<module>.api.dart`:
- Define parameter types and return type
- Follow existing method patterns in the same file

### 2. Regenerate Platform Channels

```bash
melos pigeon --no-select
```

### 3. Add Dart Method

Add the method to the module class in `packages/luciq_flutter/lib/src/modules/<module>.dart`:
- Static method calling through to the generated Pigeon host API
- Match the style of existing methods in the same class

### 4. Create Models (if needed)

Add any new models to `packages/luciq_flutter/lib/src/models/`

### 5. Update Exports (if needed)

If new models were added, export them in `packages/luciq_flutter/lib/luciq_flutter.dart`

### 6. Write Tests

Add tests to the existing test file `packages/luciq_flutter/test/<module>_test.dart`:
- Test the method calls through to the Pigeon API correctly
- Test parameter passing
- Test error handling
- Run `melos generate --no-select` if new mocks are needed

### 7. Verify

```bash
cd packages/luciq_flutter
flutter test
melos analyze
```

## Best Practices

- Parameter naming should be consistent with existing SDK conventions
- Include `@Deprecated` if replacing an existing method
- Null parameters should have sensible defaults on the native side
- Callbacks should follow existing callback patterns in the module
