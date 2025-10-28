import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter/src/utils/screen_loading/screen_loading_manager.dart';
import 'package:luciq_flutter_example/src/app_routes.dart';
import 'package:luciq_flutter_example/src/components/apm_switch.dart';
import 'package:luciq_flutter_example/src/native/luciq_flutter_example_method_channel.dart';
import 'package:luciq_flutter_example/src/screens/callback/callback_handler_provider.dart';
import 'package:luciq_flutter_example/src/screens/callback/callback_page.dart';
import 'package:luciq_flutter_example/src/utils/widget_ext.dart';
import 'package:luciq_flutter_example/src/widget/luciq_button.dart';
import 'package:luciq_flutter_example/src/widget/luciq_clipboard_input.dart';
import 'package:luciq_flutter_example/src/widget/luciq_text_field.dart';
import 'package:luciq_flutter_example/src/widget/nested_view.dart';
import 'package:luciq_flutter_example/src/widget/section_title.dart';
import 'package:luciq_http_client/luciq_http_client.dart';
import 'package:provider/provider.dart';

part 'src/components/fatal_crashes_content.dart';
part 'src/components/flows_content.dart';
part 'src/components/network_content.dart';
part 'src/components/non_fatal_crashes_content.dart';
part 'src/components/ndk_crashes_content.dart';

part 'src/components/page.dart';
part 'src/screens/apm_page.dart';
part 'src/screens/bug_reporting.dart';
part 'src/screens/complex_page.dart';
part 'src/screens/core_page.dart';
part 'src/screens/crashes_page.dart';
part 'src/screens/my_home_page.dart';
part 'src/screens/screen_capture_premature_extension_page.dart';
part 'src/screens/screen_loading_page.dart';
part 'src/screens/session_replay_page.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      Luciq.init(
        token: 'ed6f659591566da19b67857e1b9d40ab',
        invocationEvents: [InvocationEvent.floatingButton],
        debugLogsLevel: LogLevel.verbose,
        appVariant: 'variant 1',
      );

      BugReporting.setProactiveReportingConfigurations(
        const ProactiveReportingConfigs(
          enabled: true,
          gapBetweenModals: 2, //time in seconds
          modalDelayAfterDetection: 2, //time in seconds
        ),
      );

      CrashReporting.setNDKEnabled(true);

      Luciq.setWelcomeMessageMode(WelcomeMessageMode.disabled);
      FlutterError.onError = (FlutterErrorDetails details) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      };

      runApp(
        ChangeNotifierProvider(
          create: (_) => CallbackHandlersProvider(),
          child: const MyApp(),
        ),
      );
    },
    CrashReporting.reportCrash,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorObservers: [
        LuciqNavigatorObserver(),
      ],
      routes: APM.wrapRoutes(appRoutes, exclude: [CrashesPage.screenName]),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
