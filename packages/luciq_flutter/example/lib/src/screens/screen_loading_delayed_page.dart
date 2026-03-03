part of '../../main.dart';

class ScreenLoadingDelayedPage extends StatefulWidget {
  static const screenName = 'screenLoadingDelayed';

  const ScreenLoadingDelayedPage({Key? key}) : super(key: key);

  @override
  State<ScreenLoadingDelayedPage> createState() =>
      _ScreenLoadingDelayedPageState();
}

class _ScreenLoadingDelayedPageState extends State<ScreenLoadingDelayedPage> {
  List<String>? _data;
  bool _isLoading = true;
  int _loadDurationMs = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stopwatch = Stopwatch()..start();
    setState(() => _isLoading = true);

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    stopwatch.stop();
    setState(() {
      _data = List.generate(20, (i) => 'Loaded Item ${i + 1}');
      _isLoading = false;
      _loadDurationMs = stopwatch.elapsedMilliseconds;
    });

    APM.endScreenLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      title: 'Delayed Content Loading',
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'This page simulates an async data fetch with a 2-second delay. '
            'APM.endScreenLoading() is called after the data loads, extending '
            'the screen loading trace to include the async operation.',
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Data loaded in $_loadDurationMs ms',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              color: Colors.green[50],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'APM.endScreenLoading() has been called. '
                        'The screen loading trace now includes the async delay.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_data != null)
            ...(_data!.map(
              (item) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(item),
                  ),
                ),
              ),
            )),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
