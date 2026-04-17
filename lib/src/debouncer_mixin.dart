import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'debouncer.dart';
import 'debouncer_config.dart';
import 'debouncer_logger.dart';
import 'disposable.dart';
import 'lifecycle_hooks.dart';
import 'strategy/debounce_strategy.dart';
import 'strategy/trailing_edge_strategy.dart';
import 'utils/debouncer_logger.dart';
import 'utils/lifecycle_hooks.dart';

/// A mixin for [State] subclasses that manages a [Debouncer] automatically.
///
/// The debouncer is created lazily on first use and disposed alongside
/// the widget — you never need to manually call [Debouncer.dispose].
///
/// ## Basic usage
/// ```dart
/// class _SearchBarState extends State<SearchBar> with DebouncerMixin {
///   void _onChanged(String query) {
///     debounce(() => _search(query));
///   }
/// }
/// ```
///
/// ## Custom delay
/// ```dart
/// @override
/// Duration get debounceDuration => const Duration(milliseconds: 500);
/// ```
///
/// ## Custom strategy
/// ```dart
/// @override
/// DebouncerStrategy get debouncerStrategy => const LeadingEdgeStrategy();
/// ```
mixin DebouncerMixin<T extends StatefulWidget> on State<T> {
  Debouncer? _mixinDebouncer;

  /// How long to wait after the last call before firing. Default: 300 ms.
  Duration get debounceDuration => const Duration(milliseconds: 300);

  /// Which [DebouncerStrategy] to use. Default: [TrailingEdgeStrategy].
  DebouncerStrategy get debouncerStrategy => const TrailingEdgeStrategy();

  /// Optional [DebouncerLogger]. Override to enable logging.
  DebouncerLogger? get debouncerLogger => null;

  /// Optional [LifecycleHooks]. Override to receive fire/cancel callbacks.
  LifecycleHooks? get debouncerHooks => null;

  Debouncer get _debouncerInstance => _mixinDebouncer ??= Debouncer.fromConfig(
    DebouncerConfig(
      delay: debounceDuration,
      debugLabel: runtimeType.toString(),
    ),
    strategy: debouncerStrategy,
    logger: debouncerLogger,
    hooks: debouncerHooks,
  );

  /// Schedules [action] through the widget-scoped debouncer.
  void debounce(VoidCallback action) => _debouncerInstance.run(action);

  /// Cancels any currently-pending debounced action.
  void cancelDebounce() => _mixinDebouncer?.cancel();

  /// `true` if a debounced call is currently waiting to fire.
  bool get hasPendingDebounce => _mixinDebouncer?.isPending ?? false;

  @override
  void dispose() {
    _mixinDebouncer?.dispose(); 
    _mixinDebouncer = null;
    super.dispose();
  }
}