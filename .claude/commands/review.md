---
description: Code review checklist for Flutter SDK best practices
---

# Code Review

Review the current changes against Flutter SDK best practices.

## Review Categories

### 1. Platform Channel Safety
- [ ] Pigeon API contracts are consistent between Dart, iOS (Objective-C), and Android (Java)
- [ ] Platform channel calls handle `PlatformException` gracefully
- [ ] No breaking changes to existing Pigeon APIs without version bump
- [ ] Generated code is up to date (`melos pigeon --no-select`)

### 2. Public API Compatibility
- [ ] No breaking changes to exports in `lib/luciq_flutter.dart`
- [ ] New public APIs follow existing module pattern (static class in `lib/src/modules/`)
- [ ] Deprecations use `@Deprecated` annotation with migration guidance
- [ ] API naming is consistent with existing conventions

### 3. Testing
- [ ] New code has corresponding tests in `test/`
- [ ] Mock generation is up to date (`melos generate --no-select`)
- [ ] Tests cover edge cases and error paths
- [ ] No flaky or timing-dependent tests

### 4. Error Handling
- [ ] Platform exceptions are caught and handled
- [ ] No unhandled futures or missing `await`
- [ ] Errors don't crash the host app
- [ ] Null safety is properly enforced

### 5. Performance
- [ ] No expensive operations on the main isolate
- [ ] No unnecessary widget rebuilds
- [ ] NavigatorObserver doesn't block navigation
- [ ] Screen loading tracking has reasonable timeouts

### 6. Code Quality
- [ ] Passes `melos analyze`
- [ ] Follows `package:lint` rules
- [ ] No unnecessary imports or dead code
- [ ] Generated files (`*.g.dart`, `*.mocks.dart`) are not manually edited

### 7. Monorepo Impact
- [ ] Changes in `luciq_flutter` don't break dependent packages
- [ ] Version constraints between packages are correct
- [ ] CHANGELOG is updated for changed packages

### 8. Security
- [ ] No hardcoded secrets or API keys
- [ ] Sensitive data is masked via `private_views/`
- [ ] User data handling respects privacy settings
- [ ] No logging of sensitive information in release mode

## How to Use

Run the current diff through each category. For each issue found, report:
- **File:line** - exact location
- **Severity** - critical / warning / suggestion
- **Issue** - what's wrong
- **Fix** - how to fix it
