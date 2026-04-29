import 'package:flutter/services.dart';
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
      // The validation throws ArgumentError, which is swallowed by the
      // runCatching wrapper (MOB-22385) — the host must still NOT be called.
      await expectLater(
        SessionReplay.setScreenshotCaptureInterval(499),
        completes,
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

  test('[setEnabled] swallows host PlatformException (MOB-22385)', () async {
    when(mHost.setEnabled(any)).thenThrow(PlatformException(code: 'X'));
    await expectLater(SessionReplay.setEnabled(true), completes);
  });
}
