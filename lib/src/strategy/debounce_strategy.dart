import 'dart:async';
import 'package:flutter/foundation.dart';
import '../debouncer_config.dart';

/// Abstract base class for all debounce strategies.
///
/// Implement this to create a fully custom debounce behaviour and pass it
/// to [Debouncer] via the [strategy] parameter.
///
/// Example:
/// ```dart
/// class MyCustomStrategy extends DebouncerStrategy {
///   @override
///   void execute(
///     VoidCallback action,
///     DebouncerConfig config,
///     Timer? currentTimer,
///     void Function(Timer?) updateTimer,
///   ) {
///     currentTimer?.cancel();
///     // your custom logic here
///   }
/// }
/// ```
abstract class DebouncerStrategy {
  const DebouncerStrategy();

  /// Called every time [Debouncer.run] is invoked.
  ///
  /// - [action]       — the callback to (eventually) fire.
  /// - [config]       — the active [DebouncerConfig].
  /// - [currentTimer] — the in-flight [Timer], if any (may be null or inactive).
  /// - [updateTimer]  — call this to replace or clear the stored timer.
  void execute(
      VoidCallback action,
      DebouncerConfig config,
      Timer? currentTimer,
      void Function(Timer?) updateTimer,
      );
}