/// A flexible, strategy-based debouncer library for Flutter and Dart.
///
/// ## Quick start
///
/// ```dart
/// import 'package:flutter_debouncer/flutter_debouncer.dart';
///
/// final debouncer = Debouncer(delay: Duration(milliseconds: 300));
/// debouncer.run(() => print('fired!'));
/// ```
///
/// ## In a StatefulWidget (recommended)
///
/// ```dart
/// class _MyState extends State<MyWidget> with DebouncerMixin {
///   void _onChanged(String v) => debounce(() => search(v));
/// }
/// ```
library flutter_debouncer;

export 'src/debouncer.dart';
export 'src/debouncer_config.dart';
export 'src/debouncer_mixin.dart';
export 'src/extensions.dart';
export 'src/strategy/both_edge_strategy.dart';
export 'src/strategy/debounce_strategy.dart';
export 'src/strategy/leading_edge_strategy.dart';
export 'src/strategy/trailing_edge_strategy.dart';
export 'src/utils/debouncer_logger.dart';
export 'src/utils/disposable.dart';
export 'src/utils/lifecycle_hooks.dart';