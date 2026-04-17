# Changelog

All notable changes to `flutter_debouncer` will be documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

---

## 0.1.0

**Initial release.**

### Added
- `Debouncer` — core class with configurable delay and pluggable strategy.
- `DebouncerConfig` — immutable configuration (delay, label, edge flags).
- `DebouncerStrategy` — abstract base for custom strategies.
- `TrailingEdgeStrategy` — fires after the last call (default).
- `LeadingEdgeStrategy` — fires immediately, then locks for the cooldown.
- `BothEdgeStrategy` — fires on both the first and last call.
- `DebouncerMixin` — auto-managed debouncer for `StatefulWidget`.
- `debounced()` extension on `void Function()` and `void Function(A)`.
- `LifecycleHooks` — `onFire`, `onCancel`, `onDispose` callbacks.
- `DebouncerLogger` — optional debug logger with three verbosity levels.
- `Disposable` mixin — safe disposal with `StateError` on post-dispose use.
- Full test suite using `fake_async`.