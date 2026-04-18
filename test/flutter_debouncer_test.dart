// test/debouncer_mixin_test.dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debounce_kit/flutter_debounce_kit.dart';

void main() {
  // ── Trailing edge ──────────────────────────────
  group('TrailingEdgeStrategy', () {
    test('does NOT fire before delay elapses', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));

        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 299)); // just under
        expect(count, 0); // still silent
        d.dispose();
      });
    });

    test('fires exactly once after delay', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));

        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 1);
        d.dispose();
      });
    });

    test('rapid calls collapse into ONE fire', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));

        // Spam 5 calls 50ms apart — only last one should fire
        for (int i = 0; i < 5; i++) {
          d.run(() => count++);
          async.elapse(const Duration(milliseconds: 50));
        }
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 1); // NOT 5
        d.dispose();
      });
    });

    test('fires again after silence resets the window', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));

        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 1);

        d.run(() => count++);
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 2); // second independent call
        d.dispose();
      });
    });
  });

  // ── Leading edge ───────────────────────────────
  group('LeadingEdgeStrategy', () {
    test('fires IMMEDIATELY on first call', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const LeadingEdgeStrategy(),
        );

        d.run(() => count++);
        expect(count, 1); // instant — no elapse needed
        d.dispose();
      });
    });

    test('ignores calls during cooldown window', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const LeadingEdgeStrategy(),
        );

        d.run(() => count++); // fires: 1
        d.run(() => count++); // blocked
        d.run(() => count++); // blocked
        expect(count, 1);
        d.dispose();
      });
    });

    test('accepts new call once cooldown expires', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          strategy: const LeadingEdgeStrategy(),
        );

        d.run(() => count++); // fires: 1
        async.elapse(const Duration(milliseconds: 301)); // cooldown over
        d.run(() => count++); // fires: 2
        expect(count, 2);
        d.dispose();
      });
    });
  });

  // ── Both edge ──────────────────────────────────
  group('BothEdgeStrategy', () {
    test('single call fires TWICE — lead + trail', () {
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
  });

  // ── cancel() ──────────────────────────────────
  group('cancel()', () {
    test('prevents pending action from firing', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));

        d.run(() => count++);
        expect(d.isPending, true);
        d.cancel();
        expect(d.isPending, false);

        async.elapse(const Duration(milliseconds: 300));
        expect(count, 0); // nothing fired
        d.dispose();
      });
    });
  });

  // ── dispose() ─────────────────────────────────
  group('dispose()', () {
    test('throws StateError if run() called after dispose', () {
      final d = Debouncer(delay: const Duration(milliseconds: 300));
      d.dispose();
      expect(() => d.run(() {}), throwsStateError);
    });

    test('cancels any pending timer on dispose', () {
      fakeAsync((async) {
        int count = 0;
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() => count++);
        d.dispose();
        async.elapse(const Duration(milliseconds: 300));
        expect(count, 0); // timer was killed
      });
    });
  });

  // ── LifecycleHooks ────────────────────────────
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
        expect(fired, isTrue);
        d.dispose();
      });
    });

    test('onCancel is called when timer is reset by new call', () {
      fakeAsync((async) {
        int cancelCount = 0;
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          hooks: LifecycleHooks(onCancel: () => cancelCount++),
        );
        d.run(() {});
        d.run(() {}); // this cancels the first pending timer
        expect(cancelCount, 1);
        d.dispose();
      });
    });

    test('onDispose is called on dispose()', () {
      bool disposed = false;
      final d = Debouncer(
        delay: const Duration(milliseconds: 300),
        hooks: LifecycleHooks(onDispose: () => disposed = true),
      );
      d.dispose();
      expect(disposed, isTrue);
    });
  });

  // ── DebouncerConfig ───────────────────────────
  group('DebouncerConfig', () {
    test('copyWith overrides only specified fields', () {
      const original = DebouncerConfig(delay: Duration(milliseconds: 300));
      final updated = original.copyWith(delay: Duration(milliseconds: 500));
      expect(updated.delay, const Duration(milliseconds: 500));
      expect(updated.trailing, original.trailing); // unchanged
    });

    test('throws AssertionError when both edges are false', () {
      expect(
        () => DebouncerConfig(leading: false, trailing: false),
        throwsAssertionError,
      );
    });
  });

  // ── Function extensions ───────────────────────
  group('Extensions', () {
    test('.debounced() delays a zero-arg function', () {
      fakeAsync((async) {
        int count = 0;
        void fn() => count++;
        final debounced = fn.debounced(
          delay: const Duration(milliseconds: 200),
        );
        debounced();
        expect(count, 0);
        async.elapse(const Duration(milliseconds: 200));
        expect(count, 1);
      });
    });

    test('DebouncedFunction1 captures the LATEST argument', () {
      fakeAsync((async) {
        String? last;
        void fn(String s) => last = s;
        final debounced = fn.debounced(
          delay: const Duration(milliseconds: 200),
        );
        debounced('first');
        debounced('second');
        debounced('third');
        async.elapse(const Duration(milliseconds: 200));
        expect(last, 'third'); // only the last one counts
      });
    });
  });

  group('DebouncerLogger coverage', () {
    test('logFire outputs at fire level', () {
      fakeAsync((async) {
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          logger: const DebouncerLogger(
            level: DebouncerLogLevel.fire,
            prefix: '[test]',
          ),
        );
        d.run(() {});
        async.elapse(const Duration(milliseconds: 300));
        d.dispose();
        // no assertion needed — just exercising the code path
      });
    });

    test('logCancel outputs at verbose level', () {
      fakeAsync((async) {
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          logger: const DebouncerLogger(level: DebouncerLogLevel.verbose),
        );
        d.run(() {}); // first call
        d.run(() {}); // second call cancels the first → triggers logCancel
        async.elapse(const Duration(milliseconds: 300));
        d.dispose();
      });
    });

    test('logReset outputs at debug level', () {
      fakeAsync((async) {
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          logger: const DebouncerLogger(
            level: DebouncerLogLevel.debug, // most verbose
          ),
        );
        d.run(() {});
        d.run(() {}); // reset fires logReset at debug level
        async.elapse(const Duration(milliseconds: 300));
        d.dispose();
      });
    });

    test('logger is silent when enabled is false', () {
      fakeAsync((async) {
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          logger: const DebouncerLogger(enabled: false),
        );
        d.run(() {});
        d.cancel();
        async.elapse(const Duration(milliseconds: 300));
        d.dispose();
      });
    });
  });

  group('Disposable mixin coverage', () {
    test('isDisposed is false before dispose', () {
      final d = Debouncer(delay: const Duration(milliseconds: 300));
      expect(d.isDisposed, false);
      d.dispose();
    });

    test('isDisposed is true after dispose', () {
      final d = Debouncer(delay: const Duration(milliseconds: 300));
      d.dispose();
      expect(d.isDisposed, true);
    });

    test('assertNotDisposed throws with method name in message', () {
      final d = Debouncer(delay: const Duration(milliseconds: 300));
      d.dispose();
      expect(
        () => d.run(() {}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('run'),
          ),
        ),
      );
    });
  });

  group('LifecycleHooks — null safety (no crash when hooks omitted)', () {
    test('works fine with no hooks at all', () {
      fakeAsync((async) {
        final d = Debouncer(delay: const Duration(milliseconds: 300));
        d.run(() {});
        d.cancel();
        d.dispose();
        // should not throw
      });
    });

    test('onFire null does not crash', () {
      fakeAsync((async) {
        // hooks with only onCancel set — onFire is null
        final d = Debouncer(
          delay: const Duration(milliseconds: 300),
          hooks: LifecycleHooks(onCancel: () {}),
        );
        d.run(() {});
        async.elapse(const Duration(milliseconds: 300));
        d.dispose();
      });
    });
  });
}
