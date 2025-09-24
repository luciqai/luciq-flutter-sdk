import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/generated/luciq.api.g.dart';
import 'package:luciq_flutter/src/utils/feature_flags_manager.dart';
import 'package:luciq_flutter/src/utils/lcq_build_info.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'feature_flags_manager_test.mocks.dart';

@GenerateMocks([LuciqHostApi, LCQBuildInfo])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final mLuciqHost = MockLuciqHostApi();
  final mBuildInfo = MockLCQBuildInfo();

  setUpAll(() {
    FeatureFlagsManager().$setHostApi(mLuciqHost);
    LCQBuildInfo.setInstance(mBuildInfo);
  });

  tearDown(() {
    reset(mLuciqHost);
  });

  test('[getW3CFeatureFlagsHeader] should call host method on IOS', () async {
    when(mBuildInfo.isAndroid).thenReturn(false);
    when(mLuciqHost.isW3CFeatureFlagsEnabled()).thenAnswer(
      (_) => Future.value({
        "isW3cExternalTraceIDEnabled": true,
        "isW3cExternalGeneratedHeaderEnabled": true,
        "isW3cCaughtHeaderEnabled": true,
      }),
    );
    final isW3CExternalTraceID =
        await FeatureFlagsManager().getW3CFeatureFlagsHeader();
    expect(isW3CExternalTraceID.isW3cExternalTraceIDEnabled, true);
    expect(isW3CExternalTraceID.isW3cExternalGeneratedHeaderEnabled, true);
    expect(isW3CExternalTraceID.isW3cCaughtHeaderEnabled, true);

    verify(
      mLuciqHost.isW3CFeatureFlagsEnabled(),
    ).called(1);
  });

  test('[isW3CExternalTraceID] should call host method on Android', () async {
    when(mBuildInfo.isAndroid).thenReturn(true);
    when(mLuciqHost.isW3CFeatureFlagsEnabled()).thenAnswer(
      (_) => Future.value({
        "isW3cExternalTraceIDEnabled": true,
        "isW3cExternalGeneratedHeaderEnabled": true,
        "isW3cCaughtHeaderEnabled": true,
      }),
    );
    when(mLuciqHost.getNetworkBodyMaxSize()).thenAnswer(
      (_) => Future.value(10240),
    );
    await FeatureFlagsManager().registerFeatureFlagsListener();

    final isW3CExternalTraceID =
        await FeatureFlagsManager().getW3CFeatureFlagsHeader();
    expect(isW3CExternalTraceID.isW3cExternalTraceIDEnabled, true);
    expect(isW3CExternalTraceID.isW3cExternalGeneratedHeaderEnabled, true);
    expect(isW3CExternalTraceID.isW3cCaughtHeaderEnabled, true);
    verify(
      mLuciqHost.isW3CFeatureFlagsEnabled(),
    ).called(1);
  });

  test('[registerW3CFlagsListener] should call host method', () async {
    when(mLuciqHost.isW3CFeatureFlagsEnabled()).thenAnswer(
      (_) => Future.value({
        "isW3cExternalTraceIDEnabled": true,
        "isW3cExternalGeneratedHeaderEnabled": true,
        "isW3cCaughtHeaderEnabled": true,
      }),
    );
    when(mLuciqHost.getNetworkBodyMaxSize()).thenAnswer(
      (_) => Future.value(10240),
    );

    await FeatureFlagsManager().registerFeatureFlagsListener();

    verify(
      mLuciqHost.registerFeatureFlagChangeListener(),
    ).called(1);
  });
}
