part of '../../main.dart';

class LongListPage extends StatefulWidget {
  static const screenName = 'LongList';

  const LongListPage({Key? key}) : super(key: key);

  @override
  State<LongListPage> createState() => _LongListPageState();
}

class _LongListPageState extends State<LongListPage> {
  static const int _itemCount = 2000;
  static const double _scrollStepPx = 160.0;
  static const Duration _tick = Duration(milliseconds: 16); // ~60Hz

  final ScrollController _controller = ScrollController();
  Timer? _timer;
  bool _scrollDown = true;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _isRunning => _timer != null;

  void _startAutoScroll() {
    if (_timer != null) return;
    _timer = Timer.periodic(_tick, (_) => _autoScrollTick());
    setState(() {});
  }

  void _stopAutoScroll() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _autoScrollTick() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    final min = position.minScrollExtent;
    final max = position.maxScrollExtent;
    final current = position.pixels;

    final next = _scrollDown
        ? (current + _scrollStepPx)
        : (current - _scrollStepPx);
    final clamped = next.clamp(min, max).toDouble();

    // Flip direction at edges to keep the run going.
    if ((clamped - max).abs() < 0.5) _scrollDown = false;
    if ((clamped - min).abs() < 0.5) _scrollDown = true;

    _controller.jumpTo(clamped);
  }

  void _jumpToRandom() {
    if (!_controller.hasClients) return;
    final index = math.Random().nextInt(_itemCount);
    final target = (index * 72.0).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Long List (Scroll Stress)'),
        actions: [
          TextButton(
            onPressed: _isRunning ? _stopAutoScroll : _startAutoScroll,
            child: Text(
              _isRunning ? 'Stop' : 'Auto-scroll',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _jumpToRandom,
        child: const Icon(Icons.shuffle),
      ),
      body: ListView.builder(
        controller: _controller,
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          final isEven = index.isEven;
          return Container(
            color: isEven ? const Color(0xFFF7F9FC) : Colors.white,
            child: ListTile(
              title: Text('Row #$index'),
              subtitle: Text(
                'Lorem ipsum dolor sit amet • ${DateTime.now().millisecondsSinceEpoch % 10000}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
