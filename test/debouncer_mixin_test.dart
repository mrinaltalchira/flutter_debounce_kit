// test/debouncer_mixin_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_kit/flutter_debounce_kit.dart';

// A minimal widget that uses DebouncerMixin
class _TestWidget extends StatefulWidget {
  final void Function(String) onDebounced;
  const _TestWidget({required this.onDebounced});

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> with DebouncerMixin {
  @override
  Duration get debounceDuration => const Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: TextField(
          onChanged: (v) => debounce(() => widget.onDebounced(v)),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('DebouncerMixin fires once after user stops typing', (
    tester,
  ) async {
    final List<String> results = [];

    await tester.pumpWidget(_TestWidget(onDebounced: results.add));

    // Type quickly — should debounce
    await tester.enterText(find.byType(TextField), 'h');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'he');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'hel');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'hell');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'hello');

    // Wait for debounce to fire
    await tester.pump(const Duration(milliseconds: 300));

    expect(results.length, 1); // only ONE call
    expect(results.first, 'hello'); // with the LAST value
  });

  testWidgets('Mixin disposes debouncer when widget is removed', (
    tester,
  ) async {
    final List<String> results = [];

    await tester.pumpWidget(_TestWidget(onDebounced: results.add));
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump(const Duration(milliseconds: 100));

    // Remove the widget before debounce fires
    await tester.pumpWidget(const SizedBox());

    // Elapse — nothing should have leaked or crashed
    await tester.pump(const Duration(milliseconds: 300));
    expect(results, isEmpty); // timer was properly cancelled
  });
}
