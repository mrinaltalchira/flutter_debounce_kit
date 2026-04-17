/// Mixin that marks a class as holding resources that must be freed.
///
/// Applied to [Debouncer] to ensure timers are always cancelled
/// when the object is no longer needed, preventing memory leaks.
mixin Disposable {
  bool _disposed = false;

  /// Whether [dispose] has already been called on this object.
  bool get isDisposed => _disposed;

  /// Release all resources held by this object.
  ///
  /// After calling [dispose], any further calls to [run] will throw
  /// a [StateError] to surface bugs early.
  void dispose() {
    _disposed = true;
    onDispose();
  }

  /// Override in subclasses to perform actual cleanup.
  void onDispose();

  /// Throws if [dispose] has already been called.
  void assertNotDisposed(String methodName) {
    if (_disposed) {
      throw StateError(
        'Cannot call $methodName on a disposed Debouncer. '
            'Create a new Debouncer instance instead.',
      );
    }
  }
}