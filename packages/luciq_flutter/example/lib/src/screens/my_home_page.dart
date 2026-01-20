part of '../../main.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final buttonStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(Colors.lightBlue),
    foregroundColor: WidgetStateProperty.all(Colors.white),
  );

  List<ReportType> reportTypes = [];

  final primaryColorController = TextEditingController();
  final screenNameController = TextEditingController();
  final featureFlagsController = TextEditingController();
  final userAttributeKeyController = TextEditingController();

  final userAttributeValueController = TextEditingController();

  @override
  void dispose() {
    featureFlagsController.dispose();
    screenNameController.dispose();
    primaryColorController.dispose();
    super.dispose();
  }

  void restartLuciq() {
    Luciq.setEnabled(false);
    Luciq.setEnabled(true);
    BugReporting.setInvocationEvents([InvocationEvent.floatingButton]);
  }

  void setOnDismissCallback() {
    BugReporting.setOnDismissCallback((dismissType, reportType) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('On Dismiss'),
            content: Text(
              'onDismiss callback called with $dismissType and $reportType',
              key: const ValueKey('dismiss_callback_dialog_test'),
            ),
          );
        },
      );
    });
  }

  void show() {
    Luciq.show();
  }

  void reportScreenChange() {
    Luciq.reportScreenChange(screenNameController.text);
  }

  void sendBugReport() {
    BugReporting.show(ReportType.bug, [InvocationOption.emailFieldOptional]);
  }

  void sendFeedback() {
    BugReporting.show(ReportType.feedback, [
      InvocationOption.emailFieldOptional,
    ]);
  }

  void showNpsSurvey() {
    Surveys.showSurvey('pcV_mE2ttqHxT1iqvBxL0w');
  }

  void showManualSurvey() {
    Surveys.showSurvey('PMqUZXqarkOR2yGKiENB4w');
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void getCurrentSessionReplaylink() async {
    final result = await SessionReplay.getSessionReplayLink();
    final snackBar = SnackBar(content: Text(result));
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(snackBar);
  }

  void showFeatureRequests() {
    FeatureRequests.show();
  }

  void toggleReportType(ReportType reportType) {
    if (reportTypes.contains(reportType)) {
      reportTypes.remove(reportType);
    } else {
      reportTypes.add(reportType);
    }
    BugReporting.setReportTypes(reportTypes);
  }

  void changeFloatingButtonEdge() {
    BugReporting.setFloatingButtonEdge(FloatingButtonEdge.left, 200);
  }

  void setInvocationEvent(InvocationEvent invocationEvent) {
    BugReporting.setInvocationEvents([invocationEvent]);
  }

  void changePrimaryColor() async {
    final text = primaryColorController.text.replaceAll('#', '');
    await Luciq.setTheme(ThemeConfig(primaryColor: '#$text'));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void setColorTheme(ColorTheme colorTheme) {
    Luciq.setColorTheme(colorTheme);
  }

  void _navigateToBugs() {
    ///This way of navigation utilize screenLoading automatic approach [Navigator 1]
    Navigator.pushNamed(context, BugReportingPage.screenName);
  }

  void _navigateToCore() {
    ///This way of navigation utilize screenLoading automatic approach [Navigator 1]
    Navigator.pushNamed(context, CorePage.screenName);
  }

  void _navigateToCrashes() {
    ///This way of navigation utilize screenLoading automatic approach [Navigator 1]
    Navigator.pushNamed(context, CrashesPage.screenName);

    ///This way of navigation utilize screenLoading manual approach [Navigator 1]
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => const CrashesPage(),
    //     settings: const RouteSettings(name: CrashesPage.screenName),
    //   ),
    // );
  }

  void _navigateToApm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LuciqCaptureScreenLoading(
          screenName: ApmPage.screenName,
          child: ApmPage(),
        ),
        settings: const RouteSettings(name: ApmPage.screenName),
      ),
    );
  }

  void _navigateToComplex() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ComplexPage(),
        settings: const RouteSettings(name: ComplexPage.screenName),
      ),
    );
  }

  void _navigateToSessionReplay() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionReplayPage(),
        settings: const RouteSettings(name: SessionReplayPage.screenName),
      ),
    );
  }

  void _navigateToPrivateViewsStress() {
    Navigator.pushNamed(context, PrivateViewsStressPage.screenName);
  }

  void _navigateToLongList() {
    Navigator.pushNamed(context, LongListPage.screenName);
  }

  final _formUserAttributeKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Page(
      scaffoldKey: _scaffoldKey,
      title: widget.title,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
          child: const Text(
            "Hello Luciq's awesome user! The purpose of this application is to show you the different options for customizing the SDK and how easy it is to integrate it to your existing app",
            textAlign: TextAlign.center,
          ),
        ),
        LuciqButton(
          onPressed: restartLuciq,
          text: 'Restart Luciq',
          symanticLabel: 'restart_page',
        ),
        LuciqButton(
          onPressed: _navigateToBugs,
          text: 'Bug Reporting',
          symanticLabel: 'open_bug_reporting',
        ),
        LuciqButton(
          onPressed: _navigateToCore,
          text: 'Core',
          symanticLabel: 'open_core',
        ),
        const SectionTitle('Primary Color'),
        LuciqTextField(
          controller: primaryColorController,
          label: 'Enter primary color',
          symanticLabel: 'primary_color_input',
          textFieldKey: const ValueKey('enter_primary_color_input'),
        ),
        LuciqButton(
          text: 'Change Primary Color',
          onPressed: changePrimaryColor,
          symanticLabel: 'set_primary_color',
        ),
        const SectionTitle('Change Invocation Event'),
        ButtonBar(
          mainAxisSize: MainAxisSize.min,
          alignment: MainAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => setInvocationEvent(InvocationEvent.none),
              style: buttonStyle,
              child: const Text('None'),
            ).withSemanticsLabel('invocation_event_none'),
            ElevatedButton(
              onPressed: () => setInvocationEvent(InvocationEvent.shake),
              style: buttonStyle,
              child: const Text('Shake'),
            ).withSemanticsLabel('invocation_event_shake'),
            ElevatedButton(
              onPressed: () => setInvocationEvent(InvocationEvent.screenshot),
              style: buttonStyle,
              child: const Text('Screenshot'),
            ).withSemanticsLabel('invocation_event_screenshot'),
          ],
        ),
        ButtonBar(
          mainAxisSize: MainAxisSize.min,
          alignment: MainAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () =>
                  setInvocationEvent(InvocationEvent.floatingButton),
              style: buttonStyle,
              child: const Text('Floating Button'),
            ).withSemanticsLabel('invocation_event_floating_button'),
            ElevatedButton(
              onPressed: () =>
                  setInvocationEvent(InvocationEvent.twoFingersSwipeLeft),
              style: buttonStyle,
              child: const Text('Two Fingers Swipe Left'),
            ).withSemanticsLabel('invocation_event_two_fingers'),
          ],
        ),
        LuciqButton(onPressed: show, text: 'Invoke'),
        LuciqButton(
          onPressed: setOnDismissCallback,
          text: 'Set On Dismiss Callback',
        ),
        const SectionTitle('Repro Steps'),
        LuciqTextField(
          controller: screenNameController,
          label: 'Enter screen name',
          symanticLabel: 'screen_name_input',
          textFieldKey: const ValueKey('screen_name_input'),
        ),
        LuciqButton(
          text: 'Report Screen Change',
          onPressed: reportScreenChange,
          symanticLabel: 'set_screen_name',
        ),
        LuciqButton(
          onPressed: sendBugReport,
          text: 'Send Bug Report',
          symanticLabel: 'send_bug_report',
        ),
        LuciqButton(
          onPressed: showManualSurvey,
          text: 'Show Manual Survey',
          symanticLabel: 'show_manual_survery',
        ),
        const SectionTitle('Change Report Types'),
        ButtonBar(
          mainAxisSize: MainAxisSize.min,
          alignment: MainAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => toggleReportType(ReportType.bug),
              style: buttonStyle,
              child: const Text('Bug'),
            ).withSemanticsLabel('bug_report_type_bug'),
            ElevatedButton(
              onPressed: () => toggleReportType(ReportType.feedback),
              style: buttonStyle,
              child: const Text('Feedback'),
            ).withSemanticsLabel('bug_report_type_feedback'),
            ElevatedButton(
              onPressed: () => toggleReportType(ReportType.question),
              style: buttonStyle,
              child: const Text('Question'),
            ).withSemanticsLabel('bug_report_type_question'),
          ],
        ),
        LuciqButton(
          onPressed: changeFloatingButtonEdge,
          text: 'Move Floating Button to Left',
          symanticLabel: 'move_floating_button_to_left',
        ),
        LuciqButton(
          onPressed: sendFeedback,
          text: 'Send Feedback',
          symanticLabel: 'sending_feedback',
        ),
        LuciqButton(
          onPressed: showNpsSurvey,
          text: 'Show NPS Survey',
          symanticLabel: 'show_nps_survey',
        ),
        LuciqButton(
          onPressed: showManualSurvey,
          text: 'Show Multiple Questions Survey',
          symanticLabel: 'show_multi_question_survey',
        ),
        LuciqButton(
          onPressed: showFeatureRequests,
          text: 'Show Feature Requests',
          symanticLabel: 'show_feature_requests',
        ),
        LuciqButton(
          onPressed: _navigateToCrashes,
          text: 'Crashes',
          symanticLabel: 'open_crash_page',
        ),
        LuciqButton(
          onPressed: _navigateToApm,
          text: 'APM',
          symanticLabel: 'open_apm_page',
        ),
        LuciqButton(
          onPressed: _navigateToComplex,
          text: 'Complex',
          symanticLabel: 'open_complex_page',
        ),
        LuciqButton(
          onPressed: _navigateToSessionReplay,
          text: 'Session Replay',
          symanticLabel: 'open_session_replay_page',
        ),
        LuciqButton(
          onPressed: _navigateToPrivateViewsStress,
          text: 'Private Views Stress Test',
          symanticLabel: 'open_private_views_stress_test_page',
        ),
        LuciqButton(
          onPressed: _navigateToLongList,
          text: 'Long List (Scroll Stress)',
          symanticLabel: 'open_long_list_stress_page',
        ),
        const SectionTitle('Sessions Replay'),
        LuciqButton(
          onPressed: getCurrentSessionReplaylink,
          text: 'Get current session replay link',
          symanticLabel: 'get_current_session_replay_link',
        ),
        const SectionTitle('Color Theme'),
        ButtonBar(
          mainAxisSize: MainAxisSize.max,
          alignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => setColorTheme(ColorTheme.light),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
                foregroundColor: WidgetStateProperty.all(Colors.lightBlue),
              ),
              child: const Text('set_color_theme_light'),
            ).withSemanticsLabel(''),
            ElevatedButton(
              onPressed: () => setColorTheme(ColorTheme.dark),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.black),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              child: const Text('set_color_theme_dark'),
            ).withSemanticsLabel(''),
          ],
        ),
        const SectionTitle('FeatureFlags'),
        LuciqTextField(
          controller: featureFlagsController,
          label: 'Feature Flag name',
          symanticLabel: 'feature_flag_name_input',
        ),
        LuciqButton(
          onPressed: () => setFeatureFlag(),
          text: 'SetFeatureFlag',
          symanticLabel: 'set_feature_flag',
        ),
        LuciqButton(
          onPressed: () => removeFeatureFlag(),
          text: 'RemoveFeatureFlag',
          symanticLabel: 'remove_feature_flag',
        ),
        LuciqButton(
          onPressed: () => removeAllFeatureFlags(),
          text: 'RemoveAllFeatureFlags',
          symanticLabel: 'remove_all_feature_flags',
        ),
      ],
    );
  }

  setFeatureFlag() {
    Luciq.addFeatureFlags([FeatureFlag(name: featureFlagsController.text)]);
  }

  removeFeatureFlag() {
    Luciq.removeFeatureFlags([featureFlagsController.text]);
  }

  removeAllFeatureFlags() {
    Luciq.clearAllFeatureFlags();
  }
}
