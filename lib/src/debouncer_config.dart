/// Configuration options for a [Debouncer] instance.
///
/// Pass a [DebouncerConfig] to customise the delay, debug label,
/// and whether to allow leading / trailing edge execution.
class DebouncerConfig {
  /// How long to wait after the last call before executing the action.
  final Duration delay;

  /// Optional label used in log output for debugging.
  final String? debugLabel;

  /// Whether to execute on the leading edge of the timeout.
  final bool leading;

  /// Whether to execute on the trailing edge of the timeout.
  final bool trailing;

  const DebouncerConfig({
    this.delay = const Duration(milliseconds: 300),
    this.debugLabel,
    this.leading = false,
    this.trailing = true,
  }) : assert(
         leading || trailing,
         'At least one of leading or trailing must be true.',
       );

  DebouncerConfig copyWith({
    Duration? delay,
    String? debugLabel,
    bool? leading,
    bool? trailing,
  }) {
    return DebouncerConfig(
      delay: delay ?? this.delay,
      debugLabel: debugLabel ?? this.debugLabel,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
    );
  }

  @override
  String toString() =>
      'DebouncerConfig(delay: $delay, leading: $leading, trailing: $trailing, label: $debugLabel)';
}
