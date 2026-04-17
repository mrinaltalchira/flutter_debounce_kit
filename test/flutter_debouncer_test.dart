import 'package:fake_async/fake_async.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:flutter_debouncer/src/lifecycle_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrailingEdgeStrategy (default)', () {
    test('does not fire immediately', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() => count++);
        expect(count, 0);
        d.dispose();
      });
    });

    test('fires once after delay', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 1);
        d.dispose();
      });
    });

    test('resets timer on repeated calls — fires only once', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 100));
        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 100));
        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 1);
        d.dispose();
      });
    });

    test('fires again after delay resets', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 1);
        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 2);
        d.dispose();
      });
    });
  });

  group('LeadingEdgeStrategy', () {
    test('fires immediately on first call', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const LeadingEdgeStrategy(),
        );
        d.run(() => count++);
        expect(count, 1);
        d.dispose();
      });
    });

    test('does not fire again during cooldown', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const LeadingEdgeStrategy(),
        );
        d.run(() => count++);
        d.run(() => count++);
        d.run(() => count++);
        expect(count, 1);
        d.dispose();
      });
    });

    test('fires again after cooldown expires', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const LeadingEdgeStrategy(),
        );
        d.run(() => count++);
        expect(count, 1);
        async.elapse(const Duration(milliseconds: 301));
        d.run(() => count++);
        expect(count, 2);
        d.dispose();
      });
    });
  });

  group('BothEdgeStrategy', () {
    test('fires on lead and trail', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const BothEdgeStrategy(),
        );
        d.run(() => count++);
        expect(count, 1); // leading fire
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 2); // trailing fire
        d.dispose();
      });
    });

    test('single call fires twice', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const BothEdgeStrategy(),
        );
        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 2);
        d.dispose();
      });
    });
  });

  group('Debouncer.cancel()', () {
    test('cancels pending action', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() => count++);
        d.cancel();
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 0);
        d.dispose();
      });
    });
  });

  group('Debouncer.dispose()', () {
    test('throws on run after dispose', () {
      final d = Debouncer(delay: const Duration(milliseconds: 300));
      d.dispose();
      expect(() => d.run(() {}), throwsStateError);
    });

    test('isPending is false after dispose', () {
      fakeAsync((async) {
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() {});
        expect(d.isPending, true);
        d.dispose();
        expect(d.isPending, false);
      });
    });
  });

  group('LifecycleHooks', () {
    test('onFire is called when action fires', () {
      fakeAsync((async) {
        bool fired = false;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          hooks: LifecycleHooks(onFire: () => fired = true),
        );
        d.run(() {});
        async.elapse(const Duration(milliseconds: 300));
        expect(fired, true);
        d.dispose();
      });
    });

    test('onDispose is called on dispose', () {
      bool disposed = false;
      final d = Debouncer(
        delay: const Duration(milliseconds: 300),
        hooks: LifecycleHooks(onDispose: () => disposed = true),
      );
      d.dispose();
      expect(disposed, true);
    });
  });

  group('DebouncerConfig', () {
    test('copyWith overrides individual fields', () {
      const config = DebouncerConfig(delay: Duration(milliseconds: 300));
      final updated = config.copyWith(delay: Duration(milliseconds: 500));
      expect(updated.delay, const Duration(milliseconds: 500));
      expect(updated.trailing, config.trailing);
    });

    test('throws when both leading and trailing are false', () {
      expect(
            () => DebouncerConfig(leading: false, trailing: false),
        throwsAssertionError,
      );
    });
  });

  group('Function extensions', () {
    test('debounced() delays a zero-argument function', () {
      fakeAsync((async) {
        int count = 0;
        void fn() => count++;
        final debounced = fn.debounced(delay: const Duration(milliseconds: 200));
        debounced();
        expect(count, 0);
        async.elapse(const Duration(milliseconds: 200));
        expect(count, 1);
      });
    });

    test('DebouncedFunction1 captures latest argument', () {
      fakeAsync((async) {
        String? last;
        void fn(String s) => last = s;
        final debounced = fn.debounced(delay: const Duration(milliseconds: 200));
        debounced('a');
        debounced('b');
        debounced('c');
        async.elapse(const Duration(milliseconds: 200));
        expect(last, 'c');
      });
    });
  });
}