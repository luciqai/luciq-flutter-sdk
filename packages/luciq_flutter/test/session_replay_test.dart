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
}
