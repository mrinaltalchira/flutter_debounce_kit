import 'debouncer.dart';
import 'debouncer_logger.dart';
import 'strategy/debounce_strategy.dart';
import 'strategy/trailing_edge_strategy.dart';
import 'utils/debouncer_logger.dart';

/// Extension on [Function] to create debounced versions directly.
///
/// This is a convenience wrapper — under the hood it creates a [Debouncer]
/// and returns a new function that calls [Debouncer.run].
///
/// **Important**: The returned function holds a [Debouncer] internally.
/// For proper cleanup in long-lived objects, prefer creating an explicit
/// [Debouncer] and calling [Debouncer.dispose] in your [State.dispose].
///
/// ## Usage
/// ```dart
/// final debouncedSearch = _search.debounced(
///   delay: Duration(milliseconds: 300),
/// );
///
/// // Later:
/// debouncedSearch();
/// ```
extension DebouncedFunction on void Function() {
  /// Returns a debounced version of this function.
  ///
  /// Each call to the returned function resets the timer.
  /// The original function fires once the [delay] elapses.
  void Function() debounced({
    Duration delay = const Duration(milliseconds: 300),
    DebouncerStrategy strategy = const TrailingEdgeStrategy(),
    DebouncerLogger? logger,
  }) {
    final debouncer = Debouncer(
      delay: delay,
      strategy: strategy,
      logger: logger,
    );
    return () => debouncer.run(this);
  }
}

/// Extension on single-argument functions for debounced use.
///
/// ```dart
/// final debouncedOnChanged = _onChanged.debounced(
///   delay: Duration(milliseconds: 400),
/// );
///
/// TextField(onChanged: debouncedOnChanged)
/// ```
extension DebouncedFunction1<A> on void Function(A) {
  /// Returns a debounced version of this single-argument function.
  void Function(A) debounced({
    Duration delay = const Duration(milliseconds: 300),
    DebouncerStrategy strategy = const TrailingEdgeStrategy(),
    DebouncerLogger? logger,
  }) {
    A? lastArg;
    final debouncer = Debouncer(
      delay: delay,
      strategy: strategy,
      logger: logger,
    );
    return (A arg) {
      lastArg = arg;
      debouncer.run(() => this(lastArg as A));
    };
  }
}