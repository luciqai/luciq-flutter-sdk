/// Over-air (code-push) services the SDK can attribute patches to.
enum OverAirUpdateService {
  /// Shorebird code push.
  shorebird,
}

/// Describes the over-air patch the app is currently running.
class OverAirUpdate {
  /// Creates an over-air update descriptor.
  const OverAirUpdate({required this.service, required this.version});

  /// The service that delivered the patch.
  final OverAirUpdateService service;

  /// The version of the patch that is running now, e.g. the number from
  /// Shorebird's `readCurrentPatch()`.
  ///
  /// Never pass a downloaded or next patch (`readNextPatch()`): it only runs
  /// after a restart, so the current session would be mislabeled.
  final String version;
}
