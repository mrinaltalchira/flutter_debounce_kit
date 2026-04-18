import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debounce_kit/flutter_debounce_kit.dart';

void main() => runApp(const DebouncerExampleApp());

// ─────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────

class DebouncerExampleApp extends StatelessWidget {
  const DebouncerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_debouncer demos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const _DemoHome(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home scaffold with navigation rail (tablet) / bottom nav (phone)
// ─────────────────────────────────────────────────────────────

class _DemoHome extends StatefulWidget {
  const _DemoHome();

  @override
  State<_DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<_DemoHome> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
    NavigationDestination(icon: Icon(Icons.touch_app), label: 'Button'),
    NavigationDestination(icon: Icon(Icons.extension), label: 'Mixin'),
    NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Both edge'),
    NavigationDestination(icon: Icon(Icons.tune), label: 'Custom'),
  ];

  static const _pages = <Widget>[
    _SearchDemo(),
    _ButtonDemo(),
    _MixinDemo(),
    _BothEdgeDemo(),
    _CustomStrategyDemo(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations:
                  _destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Demo 1 — Search field (trailing edge, default)
//
// Shows: Debouncer class, TrailingEdgeStrategy, LifecycleHooks,
//        DebouncerLogger, adjustable delay via slider
// ─────────────────────────────────────────────────────────────

class _SearchDemo extends StatefulWidget {
  const _SearchDemo();

  @override
  State<_SearchDemo> createState() => _SearchDemoState();
}

class _SearchDemoState extends State<_SearchDemo> {
  late Debouncer _debouncer;
  double _delayMs = 400;

  int _keystrokes = 0;
  int _apiCalls = 0;
  int _cancels = 0;
  String _status = 'Start typing in the field below…';
  bool _isPending = false;

  @override
  void initState() {
    super.initState();
    _buildDebouncer();
  }

  void _buildDebouncer() {
    _debouncer = Debouncer(
      delay: Duration(milliseconds: _delayMs.round()),
      label: 'search',
      logger: DebouncerLogger(
        level: DebouncerLogLevel.debug,
        enabled: kDebugMode,
        prefix: '[SearchDemo]',
      ),
      hooks: LifecycleHooks(
        onFire: () => setState(() => _isPending = false),
        onCancel:
            () => setState(() {
              _cancels++;
              _isPending = true;
            }),
      ),
    );
  }

  void _onDelayChanged(double v) {
    _debouncer.dispose();
    setState(() => _delayMs = v);
    _buildDebouncer();
  }

  void _onChanged(String query) {
    setState(() => _keystrokes++);
    _debouncer.run(() {
      setState(() {
        _apiCalls++;
        _status =
            query.trim().isEmpty
                ? 'API called with: (empty query)'
                : 'API called with: "$query"';
      });
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Search — trailing edge',
      subtitle:
          'Fires once, ${_delayMs.round()} ms after you stop typing. '
          'Ideal for API calls on TextField.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            autofocus: true,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              labelText: 'Search query',
              prefixIcon: Icon(Icons.search),
              hintText: 'Type fast — watch the API call counter',
            ),
          ),
          const SizedBox(height: 20),
          _SliderRow(
            label: 'Delay',
            value: _delayMs,
            min: 100,
            max: 1000,
            divisions: 18,
            display: '${_delayMs.round()} ms',
            onChanged: _onDelayChanged,
          ),
          const SizedBox(height: 24),
          _StatsGrid(
            stats: {
              'Keystrokes': '$_keystrokes',
              'API calls': '$_apiCalls',
              'Cancelled': '$_cancels',
              'Pending': _isPending ? 'yes' : 'no',
            },
          ),
          const SizedBox(height: 20),
          _StatusCard(status: _status),
          const SizedBox(height: 20),
          _CodeSnippet('''
final debouncer = Debouncer(
  delay: Duration(milliseconds: ${_delayMs.round()}),
  hooks: LifecycleHooks(onFire: () => print('fired')),
);

TextField(
  onChanged: (q) => debouncer.run(() => search(q)),
)'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Demo 2 — Submit button (leading edge)
//
// Shows: LeadingEdgeStrategy, blocking duplicate taps
// ─────────────────────────────────────────────────────────────

class _ButtonDemo extends StatefulWidget {
  const _ButtonDemo();

  @override
  State<_ButtonDemo> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<_ButtonDemo> {
  final _debouncer = Debouncer(
    delay: const Duration(milliseconds: 800),
    strategy: const LeadingEdgeStrategy(),
    label: 'submit',
  );

  int _taps = 0;
  int _submitted = 0;
  final List<String> _log = [];

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _onTap() {
    final tap = ++_taps;
    setState(() => _log.insert(0, 'Tap #$tap received'));
    _debouncer.run(() {
      setState(() {
        _submitted++;
        _log.insert(0, '  → Order #$_submitted SUBMITTED');
      });
    });
  }

  void _reset() => setState(() {
    _taps = 0;
    _submitted = 0;
    _log.clear();
    _debouncer.cancel();
  });

  @override
  Widget build(BuildContext context) {
    final blocked = _taps - _submitted;
    return _DemoScaffold(
      title: 'Button — leading edge',
      subtitle:
          'Fires immediately on first tap. '
          'Extra taps within 800 ms are silently ignored.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: _onTap,
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Place order'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 18,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap repeatedly to see blocking in action',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _StatsGrid(
            stats: {
              'Total taps': '$_taps',
              'Orders placed': '$_submitted',
              'Blocked': '$blocked',
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Event log', style: Theme.of(context).textTheme.labelLarge),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                _log.isEmpty
                    ? const Center(child: Text('Tap the button above'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _log.length,
                      itemBuilder:
                          (_, i) => Text(
                            _log[i],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color:
                                  _log[i].contains('SUBMITTED')
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                          ),
                    ),
          ),
          const SizedBox(height: 20),
          _CodeSnippet('''
final debouncer = Debouncer(
  delay: Duration(milliseconds: 800),
  strategy: LeadingEdgeStrategy(),
);

ElevatedButton(
  onPressed: () => debouncer.run(submitOrder),
)'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Demo 3 — DebouncerMixin (zero boilerplate)
//
// Shows: DebouncerMixin, override debounceDuration,
//        hasPendingDebounce, cancelDebounce()
// ─────────────────────────────────────────────────────────────

class _MixinDemo extends StatefulWidget {
  const _MixinDemo();

  @override
  State<_MixinDemo> createState() => _MixinDemoState();
}

class _MixinDemoState extends State<_MixinDemo> with DebouncerMixin {
  @override
  Duration get debounceDuration => const Duration(milliseconds: 500);

  @override
  DebouncerLogger get debouncerLogger => const DebouncerLogger(
    level: DebouncerLogLevel.verbose,
    enabled: kDebugMode,
    prefix: '[MixinDemo]',
  );

  String _lastValue = '';
  int _fires = 0;
  int _keystrokes = 0;

  void _onChanged(String v) {
    setState(() => _keystrokes++);
    debounce(
      () => setState(() {
        _lastValue = v;
        _fires++;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _DemoScaffold(
      title: 'DebouncerMixin',
      subtitle:
          'Add with DebouncerMixin to any State. '
          'No manual create or dispose — the mixin handles everything.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: _onChanged,
            decoration: const InputDecoration(
              labelText: 'Type something',
              prefixIcon: Icon(Icons.keyboard),
              hintText: 'Debounced automatically via the mixin',
            ),
          ),
          const SizedBox(height: 20),
          // Live pending indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  hasPendingDebounce
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  hasPendingDebounce
                      ? Icons.hourglass_top
                      : Icons.check_circle_outline,
                  size: 18,
                  color:
                      hasPendingDebounce ? cs.onPrimaryContainer : cs.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPendingDebounce
                      ? 'Timer running — waiting for you to stop…'
                      : 'Idle — no pending call',
                  style: TextStyle(
                    color:
                        hasPendingDebounce ? cs.onPrimaryContainer : cs.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StatsGrid(
            stats: {
              'Keystrokes': '$_keystrokes',
              'Fires': '$_fires',
              'Saved calls': '${max(0, _keystrokes - _fires)}',
            },
          ),
          const SizedBox(height: 16),
          if (_lastValue.isNotEmpty)
            _StatusCard(status: 'Last debounced: "$_lastValue"'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              cancelDebounce();
              setState(() {});
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel pending'),
          ),
          const SizedBox(height: 20),
          _CodeSnippet('''
class _MyState extends State<MyWidget>
    with DebouncerMixin {

  @override
  Duration get debounceDuration =>
      const Duration(milliseconds: 500);

  void _onChanged(String v) {
    debounce(() => search(v));
  }
  // No dispose() needed!
}'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Demo 4 — Both edge (scroll position tracker)
//
// Shows: BothEdgeStrategy, fires on start AND end of scroll
// ─────────────────────────────────────────────────────────────

class _BothEdgeDemo extends StatefulWidget {
  const _BothEdgeDemo();

  @override
  State<_BothEdgeDemo> createState() => _BothEdgeDemoState();
}

class _BothEdgeDemoState extends State<_BothEdgeDemo> {
  final _debouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
    strategy: const BothEdgeStrategy(),
    label: 'scroll',
  );

  final _scrollController = ScrollController();
  final List<String> _events = [];
  int _scrollMoves = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.offset.toStringAsFixed(0);
    setState(() => _scrollMoves++);
    _debouncer.run(() {
      setState(
        () => _events.insert(
          0,
          '${_events.length.isEven ? "START" : "END  "} scroll → offset $pos px',
        ),
      );
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Both edge strategy',
      subtitle:
          'Fires on the FIRST scroll event (start) AND again '
          '500 ms after scrolling stops (end). Perfect for analytics.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: 40,
              itemBuilder:
                  (_, i) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    title: Text('Scroll item ${i + 1}'),
                    subtitle: Text('Row data goes here — item $i'),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _StatsGrid(
            stats: {
              'Scroll moves': '$_scrollMoves',
              'Events fired': '${_events.length}',
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fired events',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              TextButton.icon(
                onPressed:
                    () => setState(() {
                      _events.clear();
                      _scrollMoves = 0;
                    }),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Clear'),
              ),
            ],
          ),
          Container(
            height: 130,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                _events.isEmpty
                    ? const Center(child: Text('Scroll the list above'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _events.length,
                      itemBuilder:
                          (_, i) => Text(
                            _events[i],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color:
                                  _events[i].startsWith('START')
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                    ),
          ),
          const SizedBox(height: 20),
          _CodeSnippet('''
final debouncer = Debouncer(
  delay: Duration(milliseconds: 500),
  strategy: BothEdgeStrategy(),
);

scrollController.addListener(() {
  debouncer.run(() => trackScrollEvent(offset));
});'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Demo 5 — Custom strategy + Function extension
//
// Shows: Custom DebouncerStrategy, .debounced() extension,
//        DebouncerConfig.copyWith()
// ─────────────────────────────────────────────────────────────

/// A custom strategy that fires every Nth call only.
class EveryNthCallStrategy extends DebouncerStrategy {
  final int n;
  int _count = 0;

  EveryNthCallStrategy({this.n = 3});

  @override
  void execute(
    VoidCallback action,
    DebouncerConfig config,
    Timer? currentTimer,
    void Function(Timer?) updateTimer,
  ) {
    _count++;
    if (_count >= n) {
      _count = 0;
      action(); // fire immediately every Nth call
    }
  }
}

class _CustomStrategyDemo extends StatefulWidget {
  const _CustomStrategyDemo();

  @override
  State<_CustomStrategyDemo> createState() => _CustomStrategyDemoState();
}

class _CustomStrategyDemoState extends State<_CustomStrategyDemo> {
  int _n = 3;
  late Debouncer _debouncer;

  // Extension demo
  late void Function(String) _debouncedFn;

  int _calls = 0;
  int _fires = 0;
  String _extensionResult = '';
  int _extensionCalls = 0;
  int _extensionFires = 0;

  @override
  void initState() {
    super.initState();
    _buildDebouncer();
    _buildExtension();
  }

  void _buildDebouncer() {
    _debouncer = Debouncer.fromConfig(
      const DebouncerConfig(delay: Duration(milliseconds: 300)),
      strategy: EveryNthCallStrategy(n: _n),
    );
  }

  void _buildExtension() {
    void handler(String v) {
      setState(() {
        _extensionFires++;
        _extensionResult = v;
      });
    }

    _debouncedFn = handler.debounced(delay: const Duration(milliseconds: 400));
  }

  void _onNChanged(int v) {
    _debouncer.dispose();
    setState(() {
      _n = v;
      _calls = 0;
      _fires = 0;
    });
    _buildDebouncer();
  }

  void _tap() {
    setState(() => _calls++);
    _debouncer.run(() => setState(() => _fires++));
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Custom strategy + extension',
      subtitle:
          'Custom EveryNthCallStrategy fires on every Nth tap. '
          'Also shows the .debounced() function extension.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom strategy section
          Text(
            'Custom strategy',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _SliderRow(
            label: 'Fire every',
            value: _n.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            display: 'every $_n taps',
            onChanged: (v) => _onNChanged(v.round()),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: _tap,
              icon: const Icon(Icons.ads_click),
              label: Text('Tap (call #${_calls + 1})'),
            ),
          ),
          const SizedBox(height: 12),
          _StatsGrid(
            stats: {
              'Total taps': '$_calls',
              'Fires': '$_fires',
              'Next fire at': 'tap #${((_calls ~/ _n) * _n) + _n}',
            },
          ),
          const Divider(height: 36),

          // Function extension section
          Text(
            '.debounced() extension',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) {
              setState(() => _extensionCalls++);
              _debouncedFn(v);
            },
            decoration: const InputDecoration(
              labelText: 'Type here',
              prefixIcon: Icon(Icons.functions),
              hintText: 'Uses fn.debounced() directly',
            ),
          ),
          const SizedBox(height: 12),
          _StatsGrid(
            stats: {
              'Keystrokes': '$_extensionCalls',
              'Fires': '$_extensionFires',
            },
          ),
          if (_extensionResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            _StatusCard(status: 'Debounced value: "$_extensionResult"'),
          ],
          const SizedBox(height: 20),
          _CodeSnippet('''
// Custom strategy
class EveryNthCallStrategy extends DebouncerStrategy {
  final int n;
  int _count = 0;
  EveryNthCallStrategy({this.n = 3});

  @override
  void execute(action, config, timer, update) {
    if (++_count >= n) { _count = 0; action(); }
  }
}

// Function extension
void myFn(String v) => search(v);
final debounced = myFn.debounced(
  delay: Duration(milliseconds: 400),
);
TextField(onChanged: debounced)'''),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared layout widgets
// ─────────────────────────────────────────────────────────────

class _DemoScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _DemoScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.medium(
          title: Text(title),
          automaticallyImplyLeading: false,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, String> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          stats.entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    e.key,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;

  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(status),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CodeSnippet extends StatefulWidget {
  final String code;

  const _CodeSnippet(this.code);

  @override
  State<_CodeSnippet> createState() => _CodeSnippetState();
}

class _CodeSnippetState extends State<_CodeSnippet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.code,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _expanded ? 'Hide code' : 'View code snippet',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: SelectableText(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
