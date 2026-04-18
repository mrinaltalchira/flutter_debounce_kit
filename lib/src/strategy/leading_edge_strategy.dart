import 'dart:async';
import 'package:flutter/foundation.dart';
import '../debouncer_config.dart';
import 'debounce_strategy.dart';

/// Fires the action immediately on the **first** call, then ignores
/// subsequent calls until [DebouncerConfig.delay] has elapsed.
///
/// Ideal for button clicks and submit actions where you want instant
/// feedback but need to prevent accidental double-submission.
///
/// Timeline:
/// ```
/// calls:  --A--B--C-----------
/// fires:  --A
/// ```
class LeadingEdgeStrategy extends DebouncerStrategy {
  const LeadingEdgeStrategy();

  @override
  void execute(
    VoidCallback action,
    DebouncerConfig config,
    Timer? currentTimer,
    void Function(Timer?) updateTimer,
  ) {
    final isIdle = currentTimer == null || !currentTimer.isActive;
    currentTimer?.cancel();

    // Schedule a cooldown timer (action won't fire again until this expires).
    updateTimer(Timer(config.delay, () => updateTimer(null)));

    if (isIdle) {
      action();
    }
  }
}
