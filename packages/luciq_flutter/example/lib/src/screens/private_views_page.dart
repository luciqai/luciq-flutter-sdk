part of '../../main.dart';

/// Demonstrates and exercises every supported [LuciqPrivateView] /
/// [LuciqSliverPrivateView] scenario, so the masking behavior can be inspected
/// visually and via the live rect inspector.
class PrivateViewsPage extends StatefulWidget {
  static const screenName = 'PrivateViews';

  const PrivateViewsPage({Key? key}) : super(key: key);

  @override
  State<PrivateViewsPage> createState() => _PrivateViewsPageState();
}

class _PrivateViewsPageState extends State<PrivateViewsPage> {
  static const _filler = 25;

  bool _showConditionalPrivate = true;
  AutoMasking? _activeAutoMasking;
  String _rectsSummary = 'Tap "Inspect rects" to fetch.';

  String _autoMaskingLabel(AutoMasking? mode) {
    if (mode == null) return 'none (fast path)';
    return mode.toString().split('.').last;
  }

  void _setAutoMasking(AutoMasking? mode) {
    setState(() => _activeAutoMasking = mode);
    PrivateViewsManager.I
        .addAutoMasking(mode == null ? const [AutoMasking.none] : [mode]);
  }

  void _inspectRects() {
    final rects = PrivateViewsManager.I.getRectsOfPrivateViews();
    setState(() {
      _rectsSummary = rects.isEmpty
          ? 'No private rects on this screen.'
          : 'Found ${rects.length} private rect(s):\n'
              '${rects.map((r) => '  • ${r.left.toStringAsFixed(1)},${r.top.toStringAsFixed(1)} ${r.width.toStringAsFixed(1)}x${r.height.toStringAsFixed(1)}').join('\n')}';
    });
  }

  void _navigateToSubRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _PrivateViewsSubRoute(),
        settings: const RouteSettings(name: 'PrivateViewsSubRoute'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Views')),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Inspector ───────────────────────────────────────────────
            const SectionTitle('Live rect inspector'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _rectsSummary,
                key: const ValueKey('private_views_rects_summary'),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            LuciqButton(
              symanticLabel: 'private_views_inspect_rects',
              onPressed: _inspectRects,
              text: 'Inspect rects',
            ),

            // ── Auto-masking switcher ───────────────────────────────────
            const SectionTitle('Auto-masking mode'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Active: ${_autoMaskingLabel(_activeAutoMasking)}',
                key: const ValueKey('private_views_auto_masking_status'),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                _autoMaskingChip('none', null),
                _autoMaskingChip('labels', AutoMasking.labels),
                _autoMaskingChip('textInputs', AutoMasking.textInputs),
                _autoMaskingChip('media', AutoMasking.media),
              ],
            ),

            // ── Scenario 1: in-bounds private view ──────────────────────
            const SectionTitle('1. In-bounds private view'),
            const _ScenarioNote(
              'Private view rendered in the initially visible viewport — '
              'should always appear in the rect list.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LuciqPrivateView(
                key: const ValueKey('in_bounds_private_view'),
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  color: Colors.deepPurple.shade100,
                  child: const Text('Sensitive content (in bounds)'),
                ),
              ),
            ),

            // ── Scenario 2: nested private views ────────────────────────
            const SectionTitle('2. Nested private views'),
            const _ScenarioNote(
              'Outer + inner LuciqPrivateView. Both register, so two rects '
              'are reported (outer encloses inner).',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LuciqPrivateView(
                key: const ValueKey('outer_private_view'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.teal.shade100,
                  child: LuciqPrivateView(
                    key: const ValueKey('inner_private_view'),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      color: Colors.teal.shade300,
                      child: const Text('Inner private view'),
                    ),
                  ),
                ),
              ),
            ),

            // ── Scenario 3: conditional mount/unmount ───────────────────
            const SectionTitle('3. Conditional mount / unmount'),
            const _ScenarioNote(
              'Toggling unmounts the LuciqPrivateView, exercising the '
              'register/unregister lifecycle. Rect count should change '
              'accordingly.',
            ),
            SwitchListTile(
              key: const ValueKey('private_views_conditional_toggle'),
              title: const Text('Show conditional private view'),
              value: _showConditionalPrivate,
              onChanged: (v) => setState(() => _showConditionalPrivate = v),
            ),
            if (_showConditionalPrivate)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LuciqPrivateView(
                  key: const ValueKey('conditional_private_view'),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    color: Colors.orange.shade200,
                    child: const Text('I appear and disappear'),
                  ),
                ),
              ),

            // ── Scenario 4: auto-masking targets (TextField / Image / Text)
            const SectionTitle('4. Auto-masking targets'),
            const _ScenarioNote(
              'Switch the auto-masking mode above, then tap "Inspect rects" '
              'to confirm the matching widgets are masked.',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                key: ValueKey('auto_mask_text_field'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Type something (textInputs target)',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Plain Text widget (labels target).',
                key: ValueKey('auto_mask_text_widget'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                key: const ValueKey('auto_mask_image_widget'),
                height: 80,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                // Icon counts as media.
                child: const Icon(Icons.image, size: 48),
              ),
            ),

            // ── Scenario 5: out-of-bounds (off-screen) ──────────────────
            const SectionTitle('5. Out-of-bounds (scrolled off-screen)'),
            const _ScenarioNote(
              'A private view sits far down. Its rect is filtered when its '
              'bounds do not overlap the screenshot bounds.',
            ),
            ...List.generate(
              _filler,
              (i) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  height: 40,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: i.isEven ? Colors.blueGrey.shade50 : Colors.white,
                  child: Text('Filler row #$i'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LuciqPrivateView(
                key: const ValueKey('out_of_bounds_private_view'),
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  color: Colors.red.shade200,
                  child: const Text('Sensitive content (deep)'),
                ),
              ),
            ),

            // ── Scenario 6: sliver private view ─────────────────────────
            const SectionTitle('6. Sliver private view'),
            const _ScenarioNote(
              'LuciqSliverPrivateView inside a nested CustomScrollView.',
            ),
            SizedBox(
              height: 240,
              child: CustomScrollView(
                key: const ValueKey('sliver_private_views_scroll'),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      height: 60,
                      color: Colors.green.shade100,
                      alignment: Alignment.center,
                      child: const Text('Public sliver header'),
                    ),
                  ),
                  LuciqSliverPrivateView(
                    key: const ValueKey('sensitive_sliver'),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Container(
                          height: 40,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.green.shade50,
                          child: Text('Sensitive list item $i'),
                        ),
                        childCount: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scenario 7: sub-route (route filtering) ─────────────────
            const SectionTitle('7. Private view on a different route'),
            const _ScenarioNote(
              'Push the sub-route, tap "Inspect rects" there, then go back. '
              'Rects from the inactive route are filtered by '
              'isElementInCurrentRoute.',
            ),
            LuciqButton(
              symanticLabel: 'private_views_open_sub_route',
              onPressed: _navigateToSubRoute,
              text: 'Open sub-route',
            ),

            // ── Scenario 8: heavy tree, no private views ────────────────
            const SectionTitle('8. Heavy tree, no private views (fast path)'),
            const _ScenarioNote(
              'With auto-masking off, this many widgets cost ~O(1) because '
              'the registry-based fast path skips traversal.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                  60,
                  (i) => Chip(label: Text('chip $i')),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _autoMaskingChip(String label, AutoMasking? mode) {
    final selected = _activeAutoMasking == mode;
    return ChoiceChip(
      key: ValueKey('auto_mask_chip_${_autoMaskingLabel(mode)}'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setAutoMasking(mode),
    );
  }
}

class _ScenarioNote extends StatelessWidget {
  final String text;

  const _ScenarioNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
      ),
    );
  }
}

class _PrivateViewsSubRoute extends StatelessWidget {
  const _PrivateViewsSubRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Views — Sub-route')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LuciqPrivateView(
            key: const ValueKey('sub_route_private_view'),
            child: Container(
              height: 80,
              alignment: Alignment.center,
              color: Colors.indigo.shade100,
              child: const Text('Sensitive content on a sub-route'),
            ),
          ),
        ),
      ),
    );
  }
}
