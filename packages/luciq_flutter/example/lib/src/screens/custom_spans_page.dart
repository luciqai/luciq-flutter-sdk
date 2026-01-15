part of '../../main.dart';

class CustomSpansPage extends StatefulWidget {
  static const screenName = 'customSpans';

  const CustomSpansPage({Key? key}) : super(key: key);

  @override
  State<CustomSpansPage> createState() => _CustomSpansPageState();
}

class _CustomSpansPageState extends State<CustomSpansPage> {
  final _spanNameController = TextEditingController(text: '');
  final _activeSpans = <String, CustomSpan>{};

  @override
  void dispose() {
    _spanNameController.dispose();
    super.dispose();
  }

  Future<void> _startSpan() async {
    final name = _spanNameController.text.trim();
    if (name.isEmpty) {
      log('Please enter a span name');
      return;
    }

    if (_activeSpans.containsKey(name)) {
      log('Span "$name" is already active');
      return;
    }

    final span = await APM.startCustomSpan(name);
    if (span != null) {
      setState(() {
        _activeSpans[name] = span;
      });
      log('Started custom span: $name');
    } else {
      log('Failed to start custom span (APM may be disabled)');
    }
  }

  Future<void> _endSpan(String name) async {
    final span = _activeSpans[name];
    if (span != null) {
      await span.end();
      setState(() {
        _activeSpans.remove(name);
      });
      log('Ended custom span: $name');
    }
  }

  Future<void> _simulateOperation() async {
    log('Starting simulated operation with custom spans...');

    // Start parent operation span
    final parentSpan = await APM.startCustomSpan('Simulated Operation');

    // Simulate database query
    final dbSpan = await APM.startCustomSpan('Database Query');
    await Future.delayed(Duration(milliseconds: 100 + math.Random().nextInt(200)));
    await dbSpan?.end();

    // Simulate API call
    final apiSpan = await APM.startCustomSpan('API Request');
    await Future.delayed(Duration(milliseconds: 200 + math.Random().nextInt(300)));
    await apiSpan?.end();

    // Simulate data processing
    final processSpan = await APM.startCustomSpan('Data Processing');
    await Future.delayed(Duration(milliseconds: 50 + math.Random().nextInt(100)));
    await processSpan?.end();

    // End parent operation
    await parentSpan?.end();

    log('Simulated operation completed with spans');
  }

  Future<void> _recordCompletedSpan() async {
    final start = DateTime.now().subtract(const Duration(seconds: 5));
    final end = DateTime.now().subtract(const Duration(seconds: 2));

    await APM.addCompletedCustomSpan('Retrospective Operation', start, end);
    log('Recorded completed span: 3 seconds duration');
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      title: 'Custom Spans',
      children: [
        // Span name input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _spanNameController,
            decoration: const InputDecoration(
              labelText: 'Span Name',
              hintText: 'Enter custom span name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Control buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: _startSpan,
                child: const Text('Start Span'),
              ),
              ElevatedButton(
                onPressed: _simulateOperation,
                child: const Text('Simulate Operation'),
              ),
              ElevatedButton(
                onPressed: _recordCompletedSpan,
                child: const Text('Record Completed'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Active spans section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Active Spans:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        if (_activeSpans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No active spans'),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: _activeSpans.entries.map((entry) => Card(
                child: ListTile(
                  title: Text(entry.key),
                  subtitle: const Text('Click to end span'),
                  trailing: const Icon(Icons.stop_circle_outlined),
                  onTap: () => _endSpan(entry.key),
                ),
              )).toList(),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

