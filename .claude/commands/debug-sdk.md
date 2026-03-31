---
description: Troubleshoot common Luciq Flutter SDK issues
---

# Debug SDK

Troubleshoot common issues with the Luciq Flutter SDK.

## Common Issues

### SDK Not Initializing
1. Verify `Luciq.init()` is called before any other SDK method
2. Check the app token is correct
3. Check platform-specific setup (iOS Info.plist, Android manifest)
4. Enable verbose logging to see initialization output

### Crashes Not Captured
1. Verify `CrashReporting` is enabled
2. Check that `FlutterError.onError` is properly set up
3. Ensure `runZonedGuarded` wraps the app for async errors
4. Check if the crash is on the native side vs Dart side

### Network Requests Not Logged
1. For Dio: verify `LuciqDioInterceptor` is added to the Dio instance
2. For HttpClient: verify `LuciqHttpClient` is being used
3. Check that network logging is enabled in SDK settings

### Screen Loading Not Tracking
1. Verify `LuciqNavigatorObserver` is added to `MaterialApp.navigatorObservers`
2. Check route names match expected patterns
3. Verify screen loading tracking is started/ended correctly

### Widget Not Rendering / Screenshot Issues
1. Verify `LuciqWidget` wraps the app widget
2. Check that private views are configured for sensitive data
3. Test on both iOS and Android - rendering may differ

### Build Failures After SDK Update
1. Run `melos bootstrap` to refresh dependencies
2. Run `melos pigeon --no-select` to regenerate platform channels
3. Run `melos generate --no-select` to regenerate mocks
4. For iOS: run `melos pods --no-select`
5. Clean and rebuild: `flutter clean && flutter pub get`

## Diagnostic Commands

```bash
# Check package versions
cd packages/luciq_flutter && flutter pub deps

# Run analysis
melos analyze

# Run tests to verify SDK integrity
melos test

# Check for dependency conflicts
cd packages/luciq_flutter && flutter pub outdated
```
