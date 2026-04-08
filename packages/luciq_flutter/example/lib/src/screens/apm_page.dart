part of '../../main.dart';

class ApmPage extends StatefulWidget {
  static const screenName = 'apm';

  const ApmPage({Key? key}) : super(key: key);

  @override
  State<ApmPage> createState() => _ApmPageState();
}

class _ApmPageState extends State<ApmPage> {
  void _navigateToScreenLoading() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScreenLoadingPage(),
        settings: const RouteSettings(
          name: ScreenLoadingPage.screenName,
        ),
      ),
    );
  }

  void _navigateToCustomSpans() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomSpansPage(),
        settings: const RouteSettings(
          name: CustomSpansPage.screenName,
        ),
      ),
    );
  }

  _endAppLaunch() => APM.endAppLaunch();

  @override
  Widget build(BuildContext context) {
    return Page(
      title: 'APM',
      children: [
        const APMSwitch(),
        LuciqButton(
          text: 'End App Launch',
          symanticLabel: 'end_app_launch',
          onPressed: _endAppLaunch,
        ),
        const SectionTitle('Network'),
        const NetworkContent(),
        const SectionTitle('Flows'),
        const FlowsContent(),
        const SectionTitle('Custom UI Traces'),
        const UITracesContent(),
        const SectionTitle('Custom Spans'),
        SizedBox.fromSize(
          size: const Size.fromHeight(12),
        ),
        LuciqButton(
          text: 'Custom Spans',
          onPressed: _navigateToCustomSpans,
          symanticLabel: 'custom_spans',
        ),
        const SectionTitle('Screen Loading'),
        SizedBox.fromSize(
          size: const Size.fromHeight(12),
        ),
        LuciqButton(
          text: 'Screen Loading',
          onPressed: _navigateToScreenLoading,
          symanticLabel: 'end_screen_loading',
        ),
        SizedBox.fromSize(
          size: const Size.fromHeight(12),
        ),
        const ScreenRender(),
      ],
    );
  }
}
