class LuciqStrings {
  LuciqStrings._();

  static const String customSpanAPMDisabledMessage =
      'APM is disabled, custom span not created. Please enable APM by following the instructions at this link:\n'
      'https://docs.luciq.ai/product-guides-and-integrations/product-guides/application-performance-monitoring';
  static const String customSpanDisabled =
      'Custom span is disabled, custom span not created. Please enable Custom Span by following the instructions at this link:\n'
      'https://docs.luciq.ai/product-guides-and-integrations/product-guides/application-performance-monitoring';
  static const String customSpanSDKNotInitializedMessage =
      'Luciq API was called before the SDK is built. To build it, first by following the instructions at this link:\n'
      'https://docs.luciq.ai/product-guides-and-integrations/product-guides/application-performance-monitoring';
  static const String customSpanNameEmpty =
      'Custom span name cannot be empty. Please provide a valid name for the custom span.';
  static const String customSpanEndTimeBeforeStartTime =
      'Custom span end time must be after start time. Please provide a valid start and end time for the custom span.';
  static const String customSpanNameTruncated =
      'Custom span name truncated to 150 characters';
  static const String customSpanLimitReached =
      'Maximum number of concurrent custom spans (100) reached. Please end some spans before starting new ones.';
}
