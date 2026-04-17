# flutter_debouncer

A flexible, strategy-based debouncer for Flutter and Dart.

[![pub version](https://img.shields.io/pub/v/flutter_debouncer.svg)](https://pub.dev/packages/flutter_debouncer)
[![likes](https://img.shields.io/pub/likes/flutter_debouncer)](https://pub.dev/packages/flutter_debouncer)
[![pub points](https://img.shields.io/pub/points/flutter_debouncer)](https://pub.dev/packages/flutter_debouncer)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Features

- **Three built-in strategies** — trailing edge, leading edge, both edges
- **Pluggable strategy pattern** — drop in your own custom strategy
- **`DebouncerMixin`** — zero-boilerplate debouncing in any `StatefulWidget`
- **Function extensions** — wrap any `void Function()` or `void Function(A)` on the fly
- **Lifecycle hooks** — `onFire`, `onCancel`, `onDispose` callbacks
- **Debug logger** — three verbosity levels for tracing debounce events
- **Safe disposal** — throws `StateError` if used after `dispose()`
- **Fully tested** with `fake_async`

---

## Installation

```yaml
dependencies:
  flutter_debouncer: ^0.1.0
```

Then run:

```bash
flutter pub get
```

---

## Usage

### 1. Basic — `Debouncer` class

```dart
import 'package:flutter_debouncer/flutter_debouncer.dart';

class _MyState extends State<MyWidget> {
  final _debouncer = Debouncer(delay: Duration(milliseconds: 300));

  void _onSearchChanged(String query) {
    _debouncer.run(() => _fetchResults(query));
  }

  @override
  void dispose() {
    _debouncer.dispose(); // always dispose!
    super.dispose();
  }
}
```

---

### 2. `DebouncerMixin` — recommended for widgets

No manual `dispose()` needed — the mixin handles it automatically.

```dart
class _SearchBarState extends State<SearchBar> with DebouncerMixin {
  void _onChanged(String query) {
    debounce(() => _fetchResults(query));
  }
}
```

Override defaults on the mixin:

```dart
class _SearchBarState extends State<SearchBar> with DebouncerMixin {
  @override
  Duration get debounceDuration => const Duration(milliseconds: 500);

  @override
  DebouncerStrategy get debouncerStrategy => const LeadingEdgeStrategy();
}
```

---

### 3. Function extension

Quickly wrap any zero- or single-argument function:

```dart
// Zero-argument
final debouncedSave = _save.debounced(delay: Duration(milliseconds: 400));
debouncedSave();

// Single-argument (TextField.onChanged)
final debouncedSearch = _search.debounced(delay: Duration(milliseconds: 300));
TextField(onChanged: debouncedSearch)
```

---

### 4. Strategies

| Strategy | Fires when | Use case |
|---|---|---|
| `TrailingEdgeStrategy` *(default)* | After last call + delay | Search fields, form validation |
| `LeadingEdgeStrategy` | Immediately on first call | Button clicks, submit actions |
| `BothEdgeStrategy` | First call + last call | Scroll events needing start + end |
| Custom `DebouncerStrategy` | You decide | Any custom behaviour |

```dart
// Leading edge
final debouncer = Debouncer(
  delay: Duration(milliseconds: 500),
  strategy: LeadingEdgeStrategy(),
);

// Custom strategy
class MyStrategy extends DebouncerStrategy {
  @override
  void execute(action, config, currentTimer, updateTimer) {
    // your logic here
  }
}
```

---

### 5. Lifecycle hooks

```dart
final debouncer = Debouncer(
  delay: Duration(milliseconds: 300),
  hooks: LifecycleHooks(
    onFire: () => print('action fired'),
    onCancel: () => print('cancelled'),
    onDispose: () => print('disposed'),
  ),
);
```

---

### 6. Logging

```dart
final debouncer = Debouncer(
  delay: Duration(milliseconds: 300),
  label: 'search',
  logger: DebouncerLogger(
    level: DebouncerLogLevel.verbose,
    enabled: kDebugMode,
  ),
);
```

Log levels:

| Level | Output |
|---|---|
| `fire` | Only when action fires |
| `verbose` | Fire + cancel events |
| `debug` | Fire + cancel + every timer reset |

---

## API reference

### `Debouncer`

| Member | Type | Description |
|---|---|---|
| `run(action)` | `void` | Schedule or re-schedule the action |
| `cancel()` | `void` | Cancel the pending action |
| `dispose()` | `void` | Cancel timer and mark as disposed |
| `isPending` | `bool` | Whether a call is waiting to fire |
| `isDisposed` | `bool` | Whether `dispose()` was called |
| `config` | `DebouncerConfig` | Active configuration |

### `DebouncerConfig`

| Field | Type | Default |
|---|---|---|
| `delay` | `Duration` | `300ms` |
| `debugLabel` | `String?` | `null` |
| `leading` | `bool` | `false` |
| `trailing` | `bool` | `true` |

### `DebouncerMixin`

| Member | Description |
|---|---|
| `debounce(action)` | Schedule action through the mixin debouncer |
| `cancelDebounce()` | Cancel any pending action |
| `hasPendingDebounce` | Whether a call is currently pending |
| `debounceDuration` | Override to set delay (default: 300 ms) |
| `debouncerStrategy` | Override to set strategy |
| `debouncerLogger` | Override to attach a logger |
| `debouncerHooks` | Override to attach hooks |

---

## Testing

The library is compatible with `fake_async` for deterministic timer testing:

```dart
import 'package:fake_async/fake_async.dart';

test('fires after delay', () {
  fakeAsync((async) {
    int count = 0;
    final d = Debouncer(delay: Duration(milliseconds: 300));
    d.run(() => count++);
    expect(count, 0);
    async.elapse(Duration(milliseconds: 300));
    expect(count, 1);
    d.dispose();
  });
});
```

---

## License

MIT — see [LICENSE](LICENSE).
