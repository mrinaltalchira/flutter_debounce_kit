import 'package:flutter/foundation.dart';

/// Hooks that fire at key points in a [Debouncer]'s lifecycle.
///
/// All callbacks are optional — supply only the ones you need.
///
/// Example:
/// ```dart
/// final debouncer = Debouncer(
///   delay: Duration(milliseconds: 300),
///   hooks: LifecycleHooks(
///     onFire: () => print('action fired'),
///     onCancel: () => print('timer cancelled'),
///   ),
/// );
/// ```
class LifecycleHooks {
  /// Called just before the debounced action executes.
  final VoidCallback? onFire;

  /// Called when a pending timer is cancelled due to a new call arriving.
  final VoidCallback? onCancel;

  /// Called when [Debouncer.dispose] is invoked.
  final VoidCallback? onDispose;

  const LifecycleHooks({
    this.onFire,
    this.onCancel,
    this.onDispose,
  });
}