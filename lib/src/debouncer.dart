import 'dart:async';
import 'package:flutter/foundation.dart';
import 'debouncer_config.dart';
import 'debouncer_logger.dart';
import 'disposable.dart';
import 'lifecycle_hooks.dart';
import 'strategy/debounce_strategy.dart';
import 'strategy/trailing_edge_strategy.dart';
import 'utils/debouncer_logger.dart';
import 'utils/disposable.dart';
import 'utils/lifecycle_hooks.dart';

/// A flexible, strategy-based debouncer for Flutter and Dart.
///
/// [Debouncer] delays executing an action until a specified [delay] has
/// passed since the last invocation. The firing behaviour is controlled
/// by a pluggable [DebouncerStrategy].
///
/// ## Basic usage
/// ```dart
/// final _debouncer = Debouncer(delay: Duration(milliseconds: 300));
///
/// void onSearchChanged(String query) {
///   _debouncer.run(() => _fetchResults(query));
/// }
///
/// @override
/// void dispose() {
///   _debouncer.dispose();
///   super.dispose();
/// }
/// ```
///
/// ## Leading-edge (fires immediately, then locks)
/// ```dart
/// final _debouncer = Debouncer(
///   delay: Duration(milliseconds: 500),
///   strategy: LeadingEdgeStrategy(),
/// );
/// ```
///
/// ## With logging
/// ```dart
/// final _debouncer = Debouncer(
///   delay: Duration(milliseconds: 300),
///   logger: DebouncerLogger(level: DebouncerLogLevel.verbose),
/// );
/// ```
class Debouncer with Disposable {
  /// The active configuration (delay, label, edge flags).
  final DebouncerConfig config;

  /// The strategy that decides when and how the action fires.
  final DebouncerStrategy strategy;

  /// Optional logger for debugging debounce events.
  final DebouncerLogger? logger;

  /// Optional lifecycle hooks (onFire, onCancel, onDispose).
  final LifecycleHooks? hooks;

  Timer? _timer;

  /// Creates a [Debouncer] with the given [delay] and optional overrides.
  ///
  /// - [delay]    — how long to wait after the last call. Default: 300 ms.
  /// - [strategy] — firing behaviour. Default: [TrailingEdgeStrategy].
  /// - [logger]   — attach a [DebouncerLogger] to trace events.
  /// - [hooks]    — lifecycle callbacks (onFire, onCancel, onDispose).
  /// - [label]    — a debug label shown in log output.
  Debouncer({
    Duration delay = const Duration(milliseconds: 300),
    DebouncerStrategy? strategy,
    this.logger,
    this.hooks,
    String? label,
  })  : config = DebouncerConfig(delay: delay, debugLabel: label),
        strategy = strategy ?? const TrailingEdgeStrategy();



  /// Creates a [Debouncer] directly from a [DebouncerConfig].
  Debouncer.fromConfig(
      this.config, {
        DebouncerStrategy? strategy,
        this.logger,
        this.hooks,
      }) : strategy = strategy ?? const TrailingEdgeStrategy();

  /// Whether a call is currently pending (timer is running).
  bool get isPending => _timer != null && _timer!.isActive;

  /// Schedules [action] to run according to the active [strategy].
  ///
  /// Each call resets the internal timer (for trailing-edge strategies).
  /// Throws a [StateError] if called after [dispose].
  void run(VoidCallback action) {
    assertNotDisposed('run');

    final bool hadPendingTimer = isPending;

    strategy.execute(
          () {
        logger?.logFire(config.debugLabel);
        hooks?.onFire?.call();
        action();
      },
      config,
      _timer,
          (t) {
        _timer = t;
        if (t != null) {
          logger?.logReset(config.debugLabel, config.delay);
        }
      },
    );

    if (hadPendingTimer) {
      logger?.logCancel(config.debugLabel);
      hooks?.onCancel?.call();
    }
  }

  /// Cancels any pending action without executing it.
  void cancel() {
    if (isPending) {
      _timer?.cancel();
      _timer = null;
      logger?.logCancel(config.debugLabel);
      hooks?.onCancel?.call();
    }
  }

  /// Cancels any pending timer and marks this instance as disposed.
  ///
  /// Always call [dispose] in [State.dispose] to prevent timer leaks.
  @override
  void onDispose() {
    _timer?.cancel();
    _timer = null;
    hooks?.onDispose?.call();
  }

  @override
  String toString() =>
      'Debouncer(config: $config, isPending: $isPending, disposed: $isDisposed)';
}