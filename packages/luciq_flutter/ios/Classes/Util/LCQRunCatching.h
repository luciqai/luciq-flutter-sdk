#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Defensive @try/@catch wrapper for native Pigeon API entry points so the SDK
 * never crashes the host app. Mirrors the Dart-side `runCatching` helper at
 * `lib/src/utils/run_catching.dart` and the Android-side `RunCatching` Java
 * utility.
 *
 * Catches `NSException` — the only thing Obj-C `@try/@catch` can intercept.
 * Process-level signals (SIGSEGV, abort) and Swift errors are not caught.
 */
void LCQRunCatching(NSString *method, void (^block)(void));

/**
 * Variant of `LCQRunCatching` that returns a value, falling back to
 * `fallback` if the block throws.
 */
id _Nullable LCQRunCatchingReturn(NSString *method, id _Nullable fallback, id _Nullable (^block)(void));

NS_ASSUME_NONNULL_END
