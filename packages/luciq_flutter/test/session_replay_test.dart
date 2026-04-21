import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/generated/session_replay.api.g.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'session_replay_test.mocks.dart';

@GenerateMocks([
  SessionReplayHostApi,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mHost = MockSessionReplayHostApi();

  setUpAll(() {
    SessionReplay.$setHostApi(mHost);
  });

  test('[setEnabled] should call host method', () async {
    const isEnabled = true;
    await SessionReplay.setEnabled(isEnabled);

    verify(
      mHost.setEnabled(isEnabled),
    ).called(1);
  });

  test('[setNetworkLogsEnabled] should call host method', () async {
    const isEnabled = true;
    await SessionReplay.setNetworkLogsEnabled(isEnabled);

    verify(
      mHost.setNetworkLogsEnabled(isEnabled),
    ).called(1);
  });

  test('[setLuciqLogsEnabled] should call host method', () async {
    const isEnabled = true;
    await SessionReplay.setLuciqLogsEnabled(isEnabled);

    verify(
      mHost.setLuciqLogsEnabled(isEnabled),
    ).called(1);
  });

  test('[setUserStepsEnabled] should call host method', () async {
    const isEnabled = true;
    await SessionReplay.setUserStepsEnabled(isEnabled);

    verify(
      mHost.setUserStepsEnabled(isEnabled),
    ).called(1);
  });

  test('[getSessionReplayLink] should call host method', () async {
    const link = 'link';
    when(mHost.getSessionReplayLink()).thenAnswer((_) async => link);

    final result = await SessionReplay.getSessionReplayLink();
    expect(result, link);
    verify(
      mHost.getSessionReplayLink(),
    ).called(1);
  });

  test('[setScreenshotCapturingMode] should call host method', () async {
    await SessionReplay.setScreenshotCapturingMode(
      ScreenshotCapturingMode.frequency,
    );

    verify(
      mHost.setScreenshotCapturingMode(
        ScreenshotCapturingMode.frequency.toString(),
      ),
    ).called(1);
  });

  test('[setScreenshotCaptureInterval] should call host method', () async {
    const intervalMs = 1000;

    await SessionReplay.setScreenshotCaptureInterval(intervalMs);

    verify(
      mHost.setScreenshotCaptureInterval(intervalMs),
    ).called(1);
  });

  test(
    '[setScreenshotCaptureInterval] should reject values below minimum',
    () async {
      await expectLater(
        () => SessionReplay.setScreenshotCaptureInterval(499),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(
        mHost.setScreenshotCaptureInterval(any),
      );
    },
  );

  test(
    '[setScreenshotCaptureInterval] should accept exact minimum value',
    () async {
      const intervalMs = 500;

      await SessionReplay.setScreenshotCaptureInterval(intervalMs);

      verify(
        mHost.setScreenshotCaptureInterval(intervalMs),
      ).called(1);
    },
  );

  test('[setScreenshotQualityMode] should call host method', () async {
    await SessionReplay.setScreenshotQualityMode(
      ScreenshotQualityMode.greyScale,
    );

    verify(
      mHost.setScreenshotQualityMode(
        ScreenshotQualityMode.greyScale.toString(),
      ),
    ).called(1);
  });

  test(
    '[onShouldSyncSession] should default to syncing when no callback is set',
    () async {
      SessionReplay().onShouldSyncSession(const <String?, Object?>{});

      verify(mHost.evaluateSync(true)).called(1);
    },
  );

  test('[setSyncCallback] should bind native callback', () async {
    await SessionReplay.setSyncCallback((_) => true);

    verify(mHost.bindOnSyncCallback()).called(1);
  });

  test(
    '[onShouldSyncSession] should invoke callback and call evaluateSync with its result',
    () async {
      SessionMetadata? received;

      await SessionReplay.setSyncCallback((metadata) {
        received = metadata;
        return false;
      });

      final payload = <String?, Object?>{
        'appVersion': '1.2.3',
        'os': 'iOS 17.0',
        'device': 'iPhone15,2',
        'sessionDurationInSeconds': 42,
        'hasLinkToAppReview': true,
        'launchType': 'Cold',
        'launchDuration': 1500,
        'bugsCount': 1,
        'fatalCrashCount': 0,
        'oomCrashCount': 0,
        'networkLogs': [
          {'url': 'https://example.com', 'duration': 120, 'statusCode': 200},
        ],
      };

      SessionReplay().onShouldSyncSession(payload);

      expect(received, isNotNull);
      expect(received!.appVersion, '1.2.3');
      expect(received!.os, 'iOS 17.0');
      expect(received!.device, 'iPhone15,2');
      expect(received!.sessionDurationInSeconds, 42);
      expect(received!.hasLinkToAppReview, true);
      expect(received!.launchType, LaunchType.cold);
      expect(received!.launchDuration, 1500);
      expect(received!.bugsCount, 1);
      expect(received!.networkLogs, hasLength(1));
      expect(received!.networkLogs.first.url, 'https://example.com');
      expect(received!.networkLogs.first.statusCode, 200);

      verify(mHost.evaluateSync(false)).called(1);
    },
  );
}
