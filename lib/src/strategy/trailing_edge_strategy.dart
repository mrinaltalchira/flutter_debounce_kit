import 'dart:async';
import 'package:flutter/foundation.dart';
import '../debouncer_config.dart';
import 'debounce_strategy.dart';

/// Fires the action once, after [DebouncerConfig.delay] has passed
/// since the **last** call.
///
/// This is the default debounce behaviour — ideal for search fields,
/// form validation, and resize handlers where you only care about
/// the final value after the user stops typing.
///
/// Timeline:
/// ```
/// calls:  --A--B--C-----------
/// fires:  -------------------C
/// ```
class TrailingEdgeStrategy extends DebouncerStrategy {
  const TrailingEdgeStrategy();

  @override
  void execute(
    VoidCallback action,
    DebouncerConfig config,
    Timer? currentTimer,
    void Function(Timer?) updateTimer,
  ) {
    currentTimer?.cancel();
    updateTimer(Timer(config.delay, action));
  }
}
