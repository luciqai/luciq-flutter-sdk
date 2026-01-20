part of '../../main.dart';

/// A worst-case screen to stress private-view detection & masking.

class PrivateViewsStressPage extends StatefulWidget {
  const PrivateViewsStressPage({Key? key}) : super(key: key);

  static const screenName = '/private-views-stress';

  @override
  State<PrivateViewsStressPage> createState() => _PrivateViewsStressPageState();
}

class _PrivateViewsStressPageState extends State<PrivateViewsStressPage> {
  int _rows = 250;
  bool _includeNestedHeader = true;
  bool _includeImages = false;
  bool _wrapWholeRowPrivate = true;

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _scriptTimer;
  bool _autoScrollEnabled = false;
  bool _scrollDown = true;
  double _scrollStepPx = 420;
  Duration _scrollTick = const Duration(milliseconds: 250);
  int? _scriptSecondsLeft;

  @override
  void dispose() {
    _stopAutoScroll();
    _scriptTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Views Stress Test')),
      body: Column(
        children: [
          _controls(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              key: const PageStorageKey('private_views_stress_list'),
              controller: _scrollController,
              itemCount: _rows + (_includeNestedHeader ? 1 : 0),
              itemBuilder: (context, index) {
                if (_includeNestedHeader && index == 0) {
                  return _nestedHeader();
                }

                final rowIndex = _includeNestedHeader ? index - 1 : index;
                return _stressRow(rowIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Worst-case: many private widgets + deep widget tree.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _scriptControls(),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 90, child: Text('Rows')),
              Expanded(
                child: Slider(
                  value: _rows.toDouble(),
                  min: 50,
                  max: 800,
                  divisions: 15,
                  label: '$_rows',
                  onChanged: (v) => setState(() => _rows = v.round()),
                ),
              ),
              SizedBox(width: 60, child: Text('$_rows')),
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _includeNestedHeader,
            onChanged: (v) => setState(() => _includeNestedHeader = v),
            title: const Text('Include nested header (deep tree)'),
            subtitle: const Text('Adds many private widgets in nested layout'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _wrapWholeRowPrivate,
            onChanged: (v) => setState(() => _wrapWholeRowPrivate = v),
            title: const Text('Wrap whole row in LuciqPrivateView'),
            subtitle: const Text('Guarantees every row becomes a private view'),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _includeImages,
            onChanged: (v) => setState(() => _includeImages = v),
            title: const Text('Include images in rows'),
            subtitle: const Text('Adds extra render work (not private)'),
          ),
        ],
      ),
    );
  }

  Widget _scriptControls() {
    final isRunning = _autoScrollEnabled;
    final secondsLeft = _scriptSecondsLeft;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isRunning ? 'Auto-scroll: RUNNING' : 'Auto-scroll: STOPPED',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (secondsLeft != null)
                Text(
                  'Script: ${secondsLeft}s left',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isRunning ? _stopAutoScroll : _startAutoScroll,
                  child: Text(
                    isRunning ? 'Stop auto-scroll' : 'Start auto-scroll',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isRunning
                      ? null
                      : () => _runScriptedStress(seconds: 300),
                  child: const Text('Run 5 min scripted'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 90, child: Text('Step px')),
              Expanded(
                child: Slider(
                  value: _scrollStepPx,
                  min: 120,
                  max: 900,
                  divisions: 13,
                  label: _scrollStepPx.round().toString(),
                  onChanged: (v) => setState(() => _scrollStepPx = v),
                ),
              ),
              SizedBox(width: 60, child: Text('${_scrollStepPx.round()}')),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 90, child: Text('Tick ms')),
              Expanded(
                child: Slider(
                  value: _scrollTick.inMilliseconds.toDouble(),
                  min: 120,
                  max: 800,
                  divisions: 17,
                  label: _scrollTick.inMilliseconds.toString(),
                  onChanged: (v) => setState(
                    () => _scrollTick = Duration(milliseconds: v.round()),
                  ),
                ),
              ),
              SizedBox(width: 60, child: Text('${_scrollTick.inMilliseconds}')),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tip: Use this while running Instruments to make 500ms vs 1000ms runs comparable.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _startAutoScroll() {
    _scriptTimer?.cancel();
    setState(() {
      _autoScrollEnabled = true;
      _scriptSecondsLeft = null;
    });

    // Kick off after first frame so ListView has layout/scroll extent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(_scrollTick, (_) => _autoScrollTick());
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _scriptTimer?.cancel();
    _scriptTimer = null;
    if (mounted) {
      setState(() {
        _autoScrollEnabled = false;
        _scriptSecondsLeft = null;
      });
    }
  }

  void _runScriptedStress({required int seconds}) {
    _startAutoScroll();
    setState(() => _scriptSecondsLeft = seconds);
    _scriptTimer?.cancel();
    _scriptTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final left = (_scriptSecondsLeft ?? 0) - 1;
      if (left <= 0) {
        t.cancel();
        _stopAutoScroll();
        return;
      }
      setState(() => _scriptSecondsLeft = left);
    });
  }

  void _autoScrollTick() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final max = position.maxScrollExtent;
    final min = position.minScrollExtent;
    final current = position.pixels;

    final next = _scrollDown
        ? (current + _scrollStepPx)
        : (current - _scrollStepPx);
    final clamped = next.clamp(min, max).toDouble();

    if ((clamped - current).abs() < 1) {
      _scrollDown = !_scrollDown;
      return;
    }

    // Flip direction at ends.
    if (clamped >= max - 1) _scrollDown = false;
    if (clamped <= min + 1) _scrollDown = true;

    // Keep animation shorter than tick interval to avoid piling up animations.
    final animMs = (_scrollTick.inMilliseconds * 0.75).round().clamp(60, 600);
    _scrollController.animateTo(
      clamped,
      duration: Duration(milliseconds: animMs),
      curve: Curves.linear,
    );
  }

  Widget _nestedHeader() {
    // A deeper tree with many private widgets and nested children.
    // We mark groups as private via LuciqPrivateView so they will be masked.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LuciqPrivateView(
                  child: _fakeField(label: 'Full name', hint: 'John Doe'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LuciqPrivateView(
                  child: _fakeField(label: 'Email', hint: 'john@company.com'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LuciqPrivateView(
                  child: _fakeField(
                    label: 'Card number',
                    hint: '•••• •••• •••• 1234',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LuciqPrivateView(
                  child: _fakeField(label: 'CVV', hint: '•••'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nested private container: deep subtree.
          LuciqPrivateView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nested private section',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      12,
                      (i) => Chip(label: Text('Private tag ${i + 1}')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stressRow(int i) {
    final base = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_includeImages) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person, size: 22),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Some private values inside the row.
                  LuciqPrivateView(
                    child: Text(
                      'Private name #$i',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: LuciqPrivateView(
                          child: Text('Account: ${100000 + i}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LuciqPrivateView(
                          child: Text('Balance: \$${(i % 97) * 123}.00'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Extra depth.
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Non-private label'),
                            const SizedBox(height: 2),
                            LuciqPrivateView(
                              child: Text('Private note: row=$i'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Non-private label'),
                            const SizedBox(height: 2),
                            LuciqPrivateView(
                              child: Text(
                                'Secret token: ${i.toRadixString(16)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Optionally mark the entire row as private (guaranteed masking for each row).
    if (_wrapWholeRowPrivate) {
      return LuciqPrivateView(child: base);
    }
    return base;
  }

  Widget _fakeField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
