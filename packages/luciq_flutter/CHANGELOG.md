# Changelog

## [Unreleased](https://github.com/luciqai/luciq-flutter-sdk/compare/v18.2.0...dev)

### Added

- Guard LuciqNavigatorObserver pending-step removal to eliminate the race that could crash apps or produce incorrect screenshots during rapid route transitions. ([#23](https://github.com/luciqai/luciq-flutter-sdk/pull/23))


## [18.2.0] (https://github.com/luciqai/luciq-flutter-sdk/compare/v18.2.0...18.0.1) (November 12, 2025)

### Added

- Make `LuciqNavigatorObserver` screen report delay configurable. ([#17](https://github.com/luciqai/luciq-flutter-sdk/pull/17))

### Changed

- Bump Instabug iOS SDK to v19.1.0 ([#10](https://github.com/luciqai/luciq-flutter-sdk/pull/10)). [See release notes](https://github.com/luciqai/Luciq-iOS-sdk/releases/tag/19.1.0).

- Bump Instabug Android SDK to v18.2.0 ([#10](https://github.com/luciqai/luciq-flutter-sdk/pull/10)). [See release notes](https://github.com/luciqai/Luciq-Android-sdk/releases/tag/v18.2.0).


## [18.0.1] (https://github.com/luciqai/luciq-flutter-sdk/compare/v18.0.1...18.0.0) (October 27, 2025)

### Added

- Add support for proactive bug-reporting ([#4](https://github.com/luciqai/luciq-flutter-sdk/pull/4)).

- Add support enable/disable the automatic masking of sensitive information in network logs. ([#6](https://github.com/luciqai/luciq-flutter-sdk/pull/6)).

- Add support NDK Crash. ([#2](https://github.com/luciqai/luciq-flutter-sdk/pull/2)).

### Changed

- Bump Instabug iOS SDK to v18.0.1 ([#10](https://github.com/luciqai/luciq-flutter-sdk/pull/10)). [See release notes](https://github.com/luciqai/Luciq-iOS-sdk/releases/tag/18.0.1).

- Bump Instabug Android SDK to v18.0.1 ([#10](https://github.com/luciqai/luciq-flutter-sdk/pull/10)). [See release notes](https://github.com/luciqai/Luciq-Android-sdk/releases/tag/v18.0.1).


## [18.0.0](https://github.com/luciqai/luciq-flutter-sdk/compare/v18.0.0...dev) (September 24, 2025)

- SDK rebranded from Instabug to Luciq.