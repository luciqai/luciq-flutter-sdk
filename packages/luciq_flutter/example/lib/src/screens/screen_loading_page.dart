part of '../../main.dart';

class ScreenLoadingPage extends StatefulWidget {
  static const screenName = 'screenLoading';

  const ScreenLoadingPage({Key? key}) : super(key: key);

  @override
  State<ScreenLoadingPage> createState() => _ScreenLoadingPageState();
}

class _ScreenLoadingPageState extends State<ScreenLoadingPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _durationController = TextEditingController();
  GlobalKey _reloadKey = GlobalKey();
  final List<int> _capturedWidgets = [];
  bool _screenLoadingEnabled = true;

  void _render() {
    setState(() {
      _reloadKey = GlobalKey();
    });
  }

  void _addCapturedWidget() {
    setState(() {
      _capturedWidgets.add(_capturedWidgets.length);
    });
  }

  ///This is the production implementation as [APM.endScreenLoading()] is the method which users use from [APM] class
  void _extendScreenLoading()  => APM.endScreenLoading();

  Future<void> _extendScreenLoadingTesting() async {
    final isEnabled = await APM.isScreenLoadingEnabled();
    if (!isEnabled) {
      debugPrint(
        'Screen loading monitoring is disabled, skipping extend.',
      );
      return;
    }
    final currentUiTrace = ScreenLoadingManager.I.currentUiTrace;
    final currentTrace = ScreenLoadingManager.I.currentScreenLoadingTrace;
    final extendedEndTime =
        (currentTrace?.endTimeInMicroseconds ?? 0) +
            (int.tryParse(_durationController.text) ?? 0);
    APM.endScreenLoadingCP(
      extendedEndTime,
      currentUiTrace?.traceId ?? 0,
    );
  }

  void _toggleScreenLoading(bool value) {
    setState(() {
      _screenLoadingEnabled = value;
    });
    APM.setScreenLoadingEnabled(value);
  }

  // ── Navigation Scenarios ──

  void _navigateToComplexPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ComplexPage.monitored(),
        settings: const RouteSettings(name: ComplexPage.screenName),
      ),
    );
  }

  void _navigateToTabViewPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LuciqCaptureScreenLoading(
          screenName: ScreenLoadingTabPage.screenName,
          child: ScreenLoadingTabPage(),
        ),
        settings: const RouteSettings(
          name: ScreenLoadingTabPage.screenName,
        ),
      ),
    );
  }

  void _navigateToDelayedContentPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LuciqCaptureScreenLoading(
          screenName: ScreenLoadingDelayedPage.screenName,
          child: ScreenLoadingDelayedPage(),
        ),
        settings: const RouteSettings(
          name: ScreenLoadingDelayedPage.screenName,
        ),
      ),
    );
  }

  void _navigateToPrematureExtensionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LuciqCaptureScreenLoading(
          screenName: ScreenCapturePrematureExtensionPage.screenName,
          child: ScreenCapturePrematureExtensionPage(),
        ),
        settings: const RouteSettings(
          name: ScreenCapturePrematureExtensionPage.screenName,
        ),
      ),
    );
  }

  // ── Overlay Scenarios ──

  void _showMonitoredBottomSheet() {
    showModalBottomSheet(
      context: context,
      routeSettings: const RouteSettings(name: 'monitoredBottomSheet'),
      isScrollControlled: true,
      builder: (context) => LuciqCaptureScreenLoading(
        screenName: 'monitoredBottomSheet',
        child: DraggableScrollableSheet(
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Monitored Bottom Sheet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'This bottom sheet pushes a modal route, so LuciqNavigatorObserver '
                  'prepares a UI trace. LuciqCaptureScreenLoading measures its loading time.',
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LuciqButton(
                  text: 'End Screen Loading',
                  onPressed: () => APM.endScreenLoading(),
                  symanticLabel: 'end_screen_loading_bottom_sheet',
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 30,
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(child: Text('$index')),
                    title: Text('Bottom Sheet Item $index'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonitoredDialog() {
    showDialog(
      context: context,
      routeSettings: const RouteSettings(name: 'monitoredDialog'),
      builder: (context) => LuciqCaptureScreenLoading(
        screenName: 'monitoredDialog',
        child: AlertDialog(
          title: const Text('Monitored Dialog'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This dialog pushes a modal route, so LuciqNavigatorObserver '
                  'prepares a UI trace. LuciqCaptureScreenLoading measures '
                  'its loading time.',
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  8,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text('Dialog item ${index + 1}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => APM.endScreenLoading(),
                    child: const Text('End Screen Loading'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _openMonitoredDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // ── Manager Resets ──

  void _resetDidStartScreenLoading() {
    ScreenLoadingManager.I.resetDidStartScreenLoading();
    debugPrint('Reset didStartScreenLoading');
  }

  void _resetDidReportScreenLoading() {
    ScreenLoadingManager.I.resetDidReportScreenLoading();
    debugPrint('Reset didReportScreenLoading');
  }

  void _resetDidExtendScreenLoading() {
    ScreenLoadingManager.I.resetDidExtendScreenLoading();
    debugPrint('Reset didExtendScreenLoading');
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Screen Loading')),
      endDrawer: LuciqCaptureScreenLoading(
        screenName: 'monitoredDrawer',
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Monitored Drawer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Drawers do not push a route, so the '
                      'NavigatorObserver will not prepare a UI trace.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => APM.endScreenLoading(),
                  child: const Text('End Screen Loading'),
                ),
              ),
              ...List.generate(
                10,
                (index) => ListTile(
                  leading: const Icon(Icons.star),
                  title: Text('Drawer Item ${index + 1}'),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 40,
        child: FloatingActionButton(
          tooltip: 'Add Captured Widget',
          onPressed: _addCapturedWidget,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Navigation Scenarios ──
            LuciqCaptureScreenLoading(
          screenName: "Header",
          child: Column(
            children: [
              const AnimatedBox(),
              SizedBox.fromSize(
                size: const Size.fromHeight(12),
              ),
              LuciqButton(
                text: 'Extend Screen Loading for header',
                onPressed: _extendScreenLoading,
                symanticLabel: 'extend_screen_loading_production',
              ),
            ],
          ),
        ),
        SizedBox.fromSize(
          size: const Size.fromHeight(12),
        ),
        const SectionTitle('Navigation Scenarios'),
            LuciqButton(
              text: 'Monitored Complex Page',
              onPressed: _navigateToComplexPage,
              symanticLabel: 'monitored_complex_page',
            ),
            LuciqButton(
              text: 'Tab View Screen Loading',
              onPressed: _navigateToTabViewPage,
              symanticLabel: 'tab_view_screen_loading',
            ),
            LuciqButton(
              text: 'Delayed Content Loading',
              onPressed: _navigateToDelayedContentPage,
              symanticLabel: 'delayed_content_loading',
            ),
            LuciqButton(
              text: 'Premature Extension Page',
              onPressed: _navigateToPrematureExtensionPage,
              symanticLabel: 'premature_extension_page',
            ),

            // ── Overlay Scenarios ──
            const SectionTitle('Overlay Scenarios'),
            LuciqButton(
              text: 'Show Monitored Bottom Sheet',
              onPressed: _showMonitoredBottomSheet,
              symanticLabel: 'monitored_bottom_sheet',
            ),
            LuciqButton(
              text: 'Show Monitored Dialog',
              onPressed: _showMonitoredDialog,
              symanticLabel: 'monitored_dialog',
            ),
            LuciqButton(
              text: 'Open Monitored Drawer',
              onPressed: _openMonitoredDrawer,
              symanticLabel: 'monitored_drawer',
            ),

            // ── Screen Loading Controls ──
            const SectionTitle('Screen Loading Controls'),
            SwitchListTile(
              title: const Text('Screen Loading Enabled'),
              subtitle: Text(
                _screenLoadingEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  color: _screenLoadingEnabled ? Colors.green : Colors.red,
                ),
              ),
              value: _screenLoadingEnabled,
              onChanged: _toggleScreenLoading,
            ),
            LuciqTextField(
              label: 'Duration (microseconds)',
              controller: _durationController,
              keyboardType: TextInputType.number,
              symanticLabel: 'duration_input',
            ),
            const SizedBox(height: 8),
            LuciqButton(
              text: 'Extend Screen Loading (Production)',
              onPressed: _extendScreenLoading,
              symanticLabel: 'extend_screen_loading_production',
            ),
            LuciqButton(
              text: 'Extend Screen Loading (Testing)',
              onPressed: _extendScreenLoadingTesting,
              symanticLabel: 'extend_screen_loading_testing',
            ),

            // ── Manager Resets ──
            const SectionTitle('Manager Resets'),
            LuciqButton(
              text: 'Reset didStartScreenLoading',
              onPressed: _resetDidStartScreenLoading,
              symanticLabel: 'reset_did_start',
              backgroundColor: Colors.orange,
            ),
            LuciqButton(
              text: 'Reset didReportScreenLoading',
              onPressed: _resetDidReportScreenLoading,
              symanticLabel: 'reset_did_report',
              backgroundColor: Colors.orange,
            ),
            LuciqButton(
              text: 'Reset didExtendScreenLoading',
              onPressed: _resetDidExtendScreenLoading,
              symanticLabel: 'reset_did_extend',
              backgroundColor: Colors.orange,
            ),

            // ── Nested Captures ──
            const SectionTitle('Nested LuciqCaptureScreenLoading (6x)'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Tests multiple nested LuciqCaptureScreenLoading widgets on the same screen. '
                'Only the first matching trace should be started and reported.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: _reloadKey,
              child: LuciqCaptureScreenLoading(
                screenName: ScreenLoadingPage.screenName,
                child: LuciqCaptureScreenLoading(
                  screenName: ScreenLoadingPage.screenName,
                  child: LuciqCaptureScreenLoading(
                    screenName: 'differentScreenName',
                    child: LuciqCaptureScreenLoading(
                      screenName: ScreenLoadingPage.screenName,
                      child: LuciqCaptureScreenLoading(
                        screenName: ScreenLoadingPage.screenName,
                        child: LuciqCaptureScreenLoading(
                          screenName: ScreenLoadingPage.screenName,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            child: LuciqButton(
                              text: 'Force Re-render',
                              onPressed: _render,
                              symanticLabel: 'force_re_render',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Dynamic Captured Widgets ──
            const SectionTitle('Dynamic Captured Widgets'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Tap the + FAB to add LuciqCaptureScreenLoading widgets at runtime.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            if (_capturedWidgets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  'No captured widgets yet. Tap + to add.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 5,
                    ),
                    shrinkWrap: true,
                    itemCount: _capturedWidgets.length,
                    itemBuilder: (context, index) {
                      return LuciqCaptureScreenLoading(
                        screenName: ScreenLoadingPage.screenName,
                        child: Text(index.toString()),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
