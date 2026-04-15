# Luciq Flutter SDK - Refactoring Report

> Generated: 2026-03-30 | Branch: `fix/crash-reporting-main-thread-jank-3`

---

## Table of Contents

1. [Critical: Code Duplication](#1-critical-code-duplication)
2. [High: Long Methods](#2-high-long-methods-20-lines)
3. [High: Tight Coupling & Separation of Concerns](#3-high-tight-coupling--separation-of-concerns)
4. [High: Large Files That Should Be Split](#4-high-large-files-that-should-be-split)
5. [Medium: Inconsistent Patterns](#5-medium-inconsistent-patterns)
6. [Medium: Null Safety Issues](#6-medium-null-safety-issues)
7. [Medium: Missing Public API Documentation](#7-medium-missing-public-api-documentation)
8. [Medium: Error Handling Gaps](#8-medium-error-handling-gaps)
9. [Medium: Hardcoded Values & Magic Numbers](#9-medium-hardcoded-values--magic-numbers)
10. [Low: Widget & Accessibility Issues](#10-low-widget--accessibility-issues)
11. [Low: Deprecated API Usage](#11-low-deprecated-api-usage)
12. [Cross-Package Issues](#12-cross-package-issues)
13. [Summary Table](#summary-table)

---

## 1. Critical: Code Duplication

### 1.1 Duplicate `RouteMatcher` Classes

**Files:**
- `lib/src/utils/screen_loading/route_matcher.dart` (92 lines)
- `lib/src/utils/ui_trace/route_matcher.dart` (92 lines)

**Issue:** Identical implementations. Only the import path differs.

**Refactor:** Move to a shared location (e.g., `lib/src/utils/route_matcher.dart`) and import from both consumers.

---

### 1.2 Duplicate `UiTrace` Classes

**Files:**
- `lib/src/utils/screen_loading/ui_trace.dart` (48 lines)
- `lib/src/utils/ui_trace/ui_trace.dart` (48 lines)

**Issue:** Nearly identical code duplicated across two directories.

**Refactor:** Consolidate into a single `UiTrace` class in a shared location.

---

### 1.3 Duplicate `_calculateBodySize` Across Packages

**Files:**
- `packages/luciq_dio_interceptor/lib/luciq_dio_interceptor.dart`
- `packages/luciq_http_client/lib/luciq_http_logger.dart`

**Issue:** Exact same implementation of body size calculation in two packages.

**Refactor:** Extract to a shared utility (e.g., `luciq_flutter/lib/src/utils/body_size_calculator.dart`) or a shared base package.

---

### 1.4 Duplicate W3C Header Handling

**Files:**
- `luciq_dio_interceptor` — gets W3C header and modifies request
- `luciq_http_client` — same logic duplicated

**Refactor:** Create a reusable W3C header wrapper utility in the main package.

---

### 1.5 Duplicate Error Logging Pattern

**Files:**
- `screen_loading_manager.dart` — `_logExceptionErrorAndStackTrace()`
- `luciq_screen_render_manager.dart` — same pattern

**Refactor:** Extract to a shared utility method in `LuciqLogger`.

---

## 2. High: Long Methods (>20 lines)

### 2.1 `ScreenLoadingManager`

| Method | Lines | Location |
|--------|-------|----------|
| `endScreenLoading()` | ~100 | `screen_loading_manager.dart:307-407` |
| `reportScreenLoading()` | ~58 | `screen_loading_manager.dart:240-297` |
| `startUiTrace()` | ~46 | `screen_loading_manager.dart:142-187` |
| `wrapRoutes()` | ~24 | `screen_loading_manager.dart:422-445` |

**Refactor:** Extract validation logic into `_validateScreenLoadingEnabled()`, `_validateTraceMatch()`, etc.

---

### 2.2 `LuciqUserStepsState`

| Method | Lines | Location |
|--------|-------|----------|
| `_getWidgetDetails()` | ~51 | `luciq_user_steps.dart:132-182` |
| `_onPointerUp()` | ~31 | `luciq_user_steps.dart:51-82` |
| `build()` | ~28 | `luciq_user_steps.dart:231-259` |

**Refactor:** Extract gesture detection into a separate `GestureClassifier` class. Extract widget tree introspection into a `WidgetIntrospector` helper.

---

### 2.3 `LuciqScreenRenderManager`

| Method | Lines | Location |
|--------|-------|----------|
| `analyzeFrameTiming()` | ~39 | `luciq_screen_render_manager.dart:75-114` |
| `endScreenRenderCollector()` | ~24 | `luciq_screen_render_manager.dart:136-159` |
| `syncCollectedScreenRenderingData()` | ~22 | `luciq_screen_render_manager.dart:163-183` |

**Refactor:** Extract frame analysis logic into a `FrameAnalyzer` class.

---

### 2.4 `LuciqNavigatorObserver`

| Method | Lines | Location |
|--------|-------|----------|
| `screenChanged()` | ~53 | `luciq_navigator_observer.dart:21-75` |

**Refactor:** Extract scheduler callback logic and try-catch into smaller private methods.

---

### 2.5 `PrivateViewsManager`

| Method | Lines | Location |
|--------|-------|----------|
| `getRectsOfPrivateViews()` | ~37 | `private_views_manager.dart:121-157` |

**Refactor:** Extract the nested `findPrivateViews()` closure into a proper private method.

---

## 3. High: Tight Coupling & Separation of Concerns

### 3.1 `ScreenLoadingManager` Hard Dependencies

**Issue:** Depends directly on `APM`, `FlagsConfig`, `Luciq`, `LuciqLogger`, and itself (circular singleton checks). Makes testing difficult without mocking the entire dependency graph.

**Refactor:** Use constructor injection or a service locator pattern to inject dependencies.

---

### 3.2 `LuciqScreenRenderManager` Mixed Concerns (446 lines)

**Issue:** Single class handles:
- Frame timing analysis
- Widget binding observer management
- Crash reporting integration
- APM data reporting

**Refactor:** Split into `FrameAnalyzer`, `BindingObserverManager`, and `ScreenRenderReporter`.

---

### 3.3 Cross-Module Setup Coupling

**Issue:** `Luciq.$setup()` directly calls `BugReporting.$setup()`, `Replies.$setup()`, `Surveys.$setup()` — public modules calling private setup on other modules.

**Refactor:** Use a registration/initialization pattern where modules register themselves.

---

### 3.4 `NetworkLogger` Input Mutation

**Issue:** `network_logger.dart:85` — `data.requestHeaders['traceparent']` is modified directly on the input object without documentation or creating a copy.

**Refactor:** Document side effects clearly or create a copy before mutation.

---

## 4. High: Large Files That Should Be Split

| File | Lines | Suggested Split |
|------|-------|-----------------|
| `luciq.dart` | 556 | Core SDK init + Configuration + Enums |
| `screen_loading_manager.dart` | 459 | UI Trace Mgmt + Screen Loading Trace + Route Wrapping + Config/Validation |
| `luciq_screen_render_manager.dart` | 447 | Frame Analysis + Binding Observer + Data Collection/Reporting |
| `luciq_user_steps.dart` | 261 | Gesture Detection + Widget Introspection + State Mgmt |

---

## 5. Medium: Inconsistent Patterns

### 5.1 Singleton Pattern Inconsistency (11+ files)

**Pattern A — Factory constructor:**
```dart
// FeatureFlagsManager, W3CHeaderUtils
factory ClassName() => _instance;
```

**Pattern B — Private constructor with getter:**
```dart
// LuciqBuildInfo, LCQDateTime, ScreenNameMasker
static ClassName get I => _instance;
ClassName._();
```

**Affected classes:** `LCQDateTime`, `LuciqMonotonicClock`, `LuciqLogger`, `ScreenNameMasker`, `W3CHeaderUtils`, `LCQBuildInfo`, `FeatureFlagsManager`, `ScreenLoadingManager`, `RouteMatcher`, `LuciqScreenRenderManager`, `LuciqWidgetsBindingObserver`

**Refactor:** Standardize on one pattern. Consider a `Singleton<T>` mixin to reduce boilerplate.

---

### 5.2 Testing Hook Inconsistency

**Issue:** No consistent naming for test hooks:
- Some modules: `$setHostApi()`
- Others: `$setManager()`
- Others: `setInstance()` vs `$setInstance()`

**Refactor:** Standardize on a single naming convention (e.g., `$setInstance()` everywhere).

---

### 5.3 Callback Storage Inconsistency

- Static callbacks: `BugReporting._onInvokeCallback`
- Instance variables: `_obfuscateLogCallback` in `NetworkManager`

**Refactor:** Choose one pattern and apply consistently.

---

### 5.4 Initialization Method Naming

- `$setup()` in some modules
- `init()` in others
- `registerFeatureFlagsListener()` in others

**Refactor:** Standardize initialization naming convention across all modules.

---

## 6. Medium: Null Safety Issues

### 6.1 Unnecessary Force Unwrap (`!`) Operators

| Location | Issue |
|----------|-------|
| `luciq_user_steps.dart:144` | `context.findRenderObject()! as RenderBox` — risky cast with force unwrap |
| `luciq_user_steps.dart:146` | `_pointerDownLocation!` — could be null if timing is off |
| `screen_loading_manager.dart:273-275` | Multiple force unwraps without null guards |

**Refactor:** Replace with null-safe alternatives (`?.`, `??`, `if-null` checks).

---

### 6.2 Late Initialization Without Guarantees

**File:** `luciq_screen_render_manager.dart:22-29`

**Issue:** Multiple `late` fields initialized in `_initStaticValues()` but the callback `_timingsCallback` might be invoked before init completes.

**Refactor:** Use nullable types with null checks, or ensure initialization order is guaranteed.

---

### 6.3 Unsafe Type Casting

**File:** `private_views_manager.dart:126-127`

```dart
final rootRenderObject = context.findRenderObject() as RenderRepaintBoundary?;
if (rootRenderObject is! RenderBox) return [];
```

**Issue:** Casts to `RenderRepaintBoundary?` then checks for `RenderBox` — confusing intent.

---

## 7. Medium: Missing Public API Documentation

### 7.1 Module Methods Without Doc Comments

- `apm.dart` — `startFlow()`, `setFlowAttribute()`, `startUITrace()` have minimal docs
- `crash_reporting.dart` — `CrashReporting.enabled` field undocumented
- `network_logger.dart` — side effects on input not documented

### 7.2 Callback Typedefs Undocumented

```dart
// bug_reporting.dart:44-45
typedef OnSDKInvokeCallback = void Function();
typedef OnSDKDismissCallback = void Function(DismissType, ReportType);
```

No documentation on when/how these are called.

### 7.3 Model Classes Missing Documentation

- `network_data.dart` — No class-level docs
- `crash_data.dart` — No docs
- `theme_config.dart` — Only field docs, no class-level docs

### 7.4 Complex Utility Classes

- `w3c_header_utils.dart:48` — `generateW3CHeader()` has minimal description
- `luciq_screen_render_manager.dart` — No class docs despite 446 lines

---

## 8. Medium: Error Handling Gaps

### 8.1 Bare Exception Catching

**File:** `luciq_navigator_observer.dart:66-73`

```dart
catch (e) {
  LuciqLogger.I.e('Reporting screen change failed:', tag: Luciq.tag);
  LuciqLogger.I.e(e.toString(), tag: Luciq.tag);
}
```

**Issue:** Generic catch with two separate log calls. Should log error and stack trace together.

---

### 8.2 Silent Failures

Several methods catch all exceptions and either return `null`/`void` or log inconsistently. Should standardize error handling strategy.

---

### 8.3 Potential Memory Leak in Dio Interceptor

**File:** `luciq_dio_interceptor.dart`

**Issue:** Uses `response.requestOptions.hashCode` as key in `_requests` map. If responses are never received (e.g., timeouts), entries accumulate indefinitely.

**Refactor:** Add a TTL-based cleanup mechanism or bounded map.

---

### 8.4 Timer Leak Risk

**File:** `luciq_user_steps.dart:46`

**Issue:** `_longPressTimer` created in `_onPointerDown()` might not cancel in all disposal paths.

**Refactor:** Ensure timer is cancelled in `dispose()` and all exit paths.

---

## 9. Medium: Hardcoded Values & Magic Numbers

### 9.1 Gesture Thresholds

**File:** `luciq_user_steps.dart`

```dart
static const double _doubleTapThreshold = 300.0;
static const double _pinchSensitivity = 20.0;
static const double _swipeSensitivity = 50.0;
static const double _scrollSensitivity = 50.0;
static const double _tapSensitivity = 20 * 20;
```

These are defined locally but should be in a centralized constants file if reused.

---

### 9.2 Screen Loading Constants

**File:** `screen_loading_manager.dart`

```dart
const characterToBeRemoved = '/';   // line 122
'ROOT_PAGE'                          // line 126
```

---

### 9.3 Frame Thresholds

**File:** `luciq_screen_render_manager.dart`

```dart
double _slowFrameThresholdMs = 16.67;   // 60 FPS default
final _frozenFrameThresholdMs = 700;     // 700ms
60   // default refresh rate
10   // tolerance default
```

**Refactor:** Extract to a `ScreenRenderConstants` class.

---

## 10. Low: Widget & Accessibility Issues

### 10.1 Marker Widgets With No Functionality

**Files:**
- `luciq_private_view.dart` — Only has a `const` constructor and returns `child` in `build()`
- `luciq_sliver_private_view.dart` — Same pattern

**Issue:** These are zero-value widgets used as markers. If intentional, document clearly. Otherwise, consider using a different pattern (e.g., `InheritedWidget`, extension method, or `Key`-based identification).

---

### 10.2 Missing `Semantics` Widgets

**Files:** `luciq_widget.dart`, `luciq_private_view.dart`, `luciq_sliver_private_view.dart`, `luciq_capture_screen_loading.dart`

**Issue:** No `Semantics` wrappers for accessibility.

---

### 10.3 Mutable Static State Without Synchronization

**File:** `crash_reporting.dart:17`

```dart
static bool enabled = true;
```

**Issue:** Mutable static state could lead to race conditions in multi-isolate scenarios.

---

### 10.4 Compatibility Workaround Still Present

**File:** `luciq_capture_screen_loading.dart:70`

```dart
// ignore: invalid_null_aware_operator
WidgetsBinding.instance?.addPostFrameCallback((_) {
```

**Issue:** Pre-Flutter 3.0 compatibility check. Review if still needed.

---

## 11. Low: Deprecated API Usage

### 11.1 Deprecated SDK Method Still Present

**File:** `luciq.dart:365-370`

```dart
@Deprecated('This API is deprecated. Please use Luciq.setTheme instead.')
static Future<void> setPrimaryColor(Color color) async { ... }
```

**Action:** Plan removal timeline and communicate to consumers.

---

### 11.2 Deprecated `DioError` Usage

**File:** `luciq_dio_interceptor.dart`

**Issue:** Still references deprecated `DioError` (now `DioException`) with an ignore comment.

**Refactor:** Update to `DioException` for Dio v5+ compatibility.

---

## 12. Cross-Package Issues

### 12.1 Platform Channel Approach Inconsistency

- **Main package (`luciq_flutter`):** Uses Pigeon-generated platform channels
- **NDK package (`luciq_flutter_ndk`):** Uses manual `MethodChannel`

**Refactor:** Consider migrating NDK to Pigeon for consistency.

---

### 12.2 Async Style Inconsistency

- **Main package:** Uses `async`/`await` consistently
- **HTTP client package:** Uses `.then()` chains throughout

**Refactor:** Standardize on `async`/`await` per Dart best practices.

---

### 12.3 Missing Error Handling in NDK Package

**Files:** `luciq_flutter_ndk_method_channel.dart`

**Issue:** No try-catch around `invokeMethod`, no timeout handling, no null return handling.

---

### 12.4 Unresolved TODOs

**File:** `screen_loading_trace.dart:18-23`

```dart
// TODO: Only startTimeInMicroseconds should be a Unix epoch timestamp
// TODO: endTimeInMicroseconds depend on one another, so we can turn one into a getter
```

**Action:** Address or create tracking issues.

---

### 12.5 Lint Suppression Comments (19+ occurrences)

Multiple `// ignore: use_setters_to_change_properties` and `// ignore: avoid_setters_without_getters` across files.

**Refactor:** Evaluate whether setters are the right pattern for singleton instance replacement, or update the lint configuration.

---

## Summary Table

| # | Category | Severity | Effort | Items |
|---|----------|----------|--------|-------|
| 1 | Code Duplication | **Critical** | Low-Med | 5 |
| 2 | Long Methods (>20 lines) | **High** | Medium | 12 |
| 3 | Tight Coupling | **High** | High | 4 |
| 4 | Large Files to Split | **High** | Medium | 4 |
| 5 | Inconsistent Patterns | **Medium** | Medium | 4 |
| 6 | Null Safety Issues | **Medium** | Medium | 3 |
| 7 | Missing Documentation | **Medium** | Medium | 4 |
| 8 | Error Handling Gaps | **Medium** | Low | 4 |
| 9 | Hardcoded Values | **Medium** | Low | 3 |
| 10 | Widget & Accessibility | **Low** | Low | 4 |
| 11 | Deprecated API Usage | **Low** | Low | 2 |
| 12 | Cross-Package Issues | **Low-Med** | Medium | 5 |

---

## Strengths Worth Preserving

- Consistent use of `LuciqLogger` (no rogue `print()` calls)
- Good test visibility with `@visibleForTesting` annotations
- Proper null-safe return types in most public APIs
- Well-structured module organization (modules/models/utils separation)
- Good use of extensions for readable code (enum converters, gesture types)
- Pigeon-based platform channel architecture in main package
- Comprehensive test coverage (31+ test files)

---

## Recommended Priority Order

1. **Deduplicate `RouteMatcher` & `UiTrace`** — Quick win, zero risk
2. **Deduplicate `_calculateBodySize` & W3C header logic** — Cross-package cleanup
3. **Split large files** (`ScreenLoadingManager`, `LuciqScreenRenderManager`) — Improves maintainability
4. **Extract long methods** — Improves readability and testability
5. **Standardize singleton pattern** — Reduces boilerplate and confusion
6. **Add missing public API docs** — Helps consumers and IDE tooling
7. **Fix null safety issues** — Prevents runtime crashes
8. **Standardize async patterns across packages** — Consistency
9. **Address deprecated API usage** — Future-proofing
10. **Add `Semantics` wrappers** — Accessibility compliance
