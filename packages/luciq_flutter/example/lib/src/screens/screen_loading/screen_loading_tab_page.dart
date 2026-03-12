part of '../../../main.dart';

class ScreenLoadingTabPage extends StatefulWidget {
  static const screenName = 'screenLoadingTabView';

  const ScreenLoadingTabPage({Key? key}) : super(key: key);

  @override
  State<ScreenLoadingTabPage> createState() => _ScreenLoadingTabPageState();
}

class _ScreenLoadingTabPageState extends State<ScreenLoadingTabPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ScreenLoadingManager.I.resetDidStartScreenLoading();
      ScreenLoadingManager.I.resetDidReportScreenLoading();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tab View Screen Loading'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.list), text: 'List'),
            Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HomeTab(key: const ValueKey('home_tab')),
          _ListTab(key: const ValueKey('list_tab')),
          _GridTab(key: const ValueKey('grid_tab')),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LuciqCaptureScreenLoading(
      screenName: ScreenLoadingTabPage.screenName,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Home Tab',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Each tab is wrapped with LuciqCaptureScreenLoading. '
                'Tab switches reset didStartScreenLoading and '
                'didReportScreenLoading to allow new traces.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              LuciqButton(
                text: 'End Screen Loading',
                onPressed: () => APM.endScreenLoading(),
                symanticLabel: 'end_screen_loading_home_tab',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LuciqCaptureScreenLoading(
      screenName: ScreenLoadingTabPage.screenName,
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(child: Text('$index')),
          title: Text('List Item $index'),
          subtitle: const Text('Screen loading tracked per tab switch'),
        ),
      ),
    );
  }
}

class _GridTab extends StatelessWidget {
  const _GridTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LuciqCaptureScreenLoading(
      screenName: ScreenLoadingTabPage.screenName,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 30,
        itemBuilder: (context, index) => Card(
          color: Colors.primaries[index % Colors.primaries.length].shade100,
          child: Center(
            child: Text(
              'Item\n$index',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
