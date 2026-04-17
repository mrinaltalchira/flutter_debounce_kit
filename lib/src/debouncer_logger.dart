// ignore_for_file: avoid_print

/// Log levels used by [DebouncerLogger].
enum DebouncerLogLevel {
  /// Only log when an action fires.
  fire,

  /// Log fire and cancel events.
  verbose,

  /// Log everything including timer resets.
  debug,
}

/// Optional logger you can attach to a [Debouncer] for debugging.
///
/// In release builds you should either omit the logger or set
/// [enabled] to `false` to avoid any performance overhead.
///
/// Example:
/// ```dart
/// final debouncer = Debouncer(
///   delay: Duration(milliseconds: 300),
///   logger: DebouncerLogger(level: DebouncerLogLevel.verbose),
/// );
/// ```
class DebouncerLogger {
  /// The minimum log level to output.
  final DebouncerLogLevel level;

  /// Whether logging is active. Defaults to `true` in debug mode.
  final bool enabled;

  /// Optional prefix prepended to every log line.
  final String prefix;

  const DebouncerLogger({
    this.level = DebouncerLogLevel.verbose,
    this.enabled = true,
    this.prefix = '[Debouncer]',
  });

  void logFire(String? label) {
    if (!enabled) return;
    _log('▶ fired${label != null ? ' ($label)' : ''}');
  }

  void logCancel(String? label) {
    if (!enabled || level == DebouncerLogLevel.fire) return;
    _log('✕ cancelled${label != null ? ' ($label)' : ''}');
  }

  void logReset(String? label, Duration delay) {
    if (!enabled || level != DebouncerLogLevel.debug) return;
    _log('↺ reset${label != null ? ' ($label)' : ''} — next fire in ${delay.inMilliseconds}ms');
  }

  void _log(String message) => print('$prefix $message');
}