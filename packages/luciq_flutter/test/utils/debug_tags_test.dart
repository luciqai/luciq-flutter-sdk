import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/constants/debug_tags.dart';

void main() {
  group('DebugTags', () {
    test('all tags are non-empty and end with a colon', () {
      const tags = <String>[
        DebugTags.core,
        DebugTags.screenTracking,
        DebugTags.apmScreenLoading,
        DebugTags.apmScreenRendering,
        DebugTags.apmUITrace,
        DebugTags.apmAppLaunch,
        DebugTags.apmCustomSpan,
        DebugTags.apmFlow,
        DebugTags.apmNetwork,
        DebugTags.bugReporting,
        DebugTags.crashReporting,
        DebugTags.sessionReplay,
        DebugTags.privateView,
        DebugTags.featureFlags,
        DebugTags.network,
        DebugTags.surveys,
        DebugTags.replies,
        DebugTags.featureRequests,
        DebugTags.appState,
        DebugTags.luciqLog,
      ];
      for (final t in tags) {
        expect(t, isNotEmpty);
        expect(t.startsWith('LCQ-Flutter-'), isTrue, reason: t);
        expect(t.endsWith(':'), isTrue, reason: t);
      }
    });

    test('all tags are unique', () {
      final tags = <String>{
        DebugTags.core,
        DebugTags.screenTracking,
        DebugTags.apmScreenLoading,
        DebugTags.apmScreenRendering,
        DebugTags.apmUITrace,
        DebugTags.apmAppLaunch,
        DebugTags.apmCustomSpan,
        DebugTags.apmFlow,
        DebugTags.apmNetwork,
        DebugTags.bugReporting,
        DebugTags.crashReporting,
        DebugTags.sessionReplay,
        DebugTags.privateView,
        DebugTags.featureFlags,
        DebugTags.network,
        DebugTags.surveys,
        DebugTags.replies,
        DebugTags.featureRequests,
        DebugTags.appState,
        DebugTags.luciqLog,
      };
      expect(tags.length, 20);
    });
  });
}
