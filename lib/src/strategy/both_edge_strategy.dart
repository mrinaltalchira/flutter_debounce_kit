import 'dart:async';
import 'package:flutter/foundation.dart';
import '../debouncer_config.dart';
import 'debounce_strategy.dart';

/// Fires the action on **both** the leading and trailing edge.
///
/// - Leading fire: immediate on first call.
/// - Trailing fire: once more after [DebouncerConfig.delay] has passed
///   since the last call — but only if there were additional calls after
///   the initial leading fire.
///
/// Timeline:
/// ```
/// calls:  --A--B--C-----------
/// fires:  --A----------------C
/// ```
class BothEdgeStrategy extends DebouncerStrategy {
  const BothEdgeStrategy();

  @override
  void execute(
      VoidCallback action,
      DebouncerConfig config,
      Timer? currentTimer,
      void Function(Timer?) updateTimer,
      ) {
    final isIdle = currentTimer == null || !currentTimer.isActive;

    currentTimer?.cancel();

    // Always schedule a trailing fire.
    updateTimer(Timer(config.delay, () {
      action();
      updateTimer(null);
    }));

    // Leading fire on first call only.
    if (isIdle) {
      action();
    }
  }
}