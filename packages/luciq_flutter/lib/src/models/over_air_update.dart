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

  /// The patch version, e.g. the number from Shorebird's `readCurrentPatch()`.
  final String version;
}
