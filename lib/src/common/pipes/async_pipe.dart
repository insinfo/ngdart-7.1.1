import 'dart:async';

import 'package:ngdart/src/core/change_detection/change_detector_ref.dart';
import 'package:ngdart/src/meta.dart';

import 'invalid_pipe_argument_exception.dart' show InvalidPipeArgumentException;

class _ObservableStrategy {
  StreamSubscription<Object?> createSubscription(
      Stream<Object?> stream, void Function(Object?) updateLatestValue) {
    return stream.listen(updateLatestValue);
  }

  void dispose(StreamSubscription<Object?> subscription) {
    subscription.cancel();
  }

  void onDestroy(StreamSubscription<Object?> subscription) {
    dispose(subscription);
  }
}

class _PromiseStrategy {
  dynamic createSubscription(
      Future<dynamic> async, dynamic Function(dynamic) updateLatestValue) {
    return async.then(updateLatestValue);
  }

  void dispose(dynamic subscription) {}
  void onDestroy(dynamic subscription) {}
}

final _promiseStrategy = _PromiseStrategy();
final _observableStrategy = _ObservableStrategy();

/// An `async` pipe awaits for a value from a [Future] or [Stream]. When a value
/// is received, the `async` pipe marks the component to be checked for changes.
///
/// ### Example
///
/// <?code-excerpt "common/pipes/lib/async_pipe.dart (AsyncPipe)"?>
/// ```dart
/// @Component(
///     selector: 'async-greeter',
///     template: '''
///       <div>
///         <p>Wait for it ... {{ $pipe.async(greeting) }}</p>
///         <button [disabled]="!done" (click)="tryAgain()">Try Again!</button>
///       </div>''')
/// class AsyncGreeterPipe {
///   static const _delay = const Duration(seconds: 2);
///
///   Future<String> greeting;
///   bool done;
///
///   AsyncGreeterPipe() {
///     tryAgain();
///   }
///
///   String greet() {
///     done = true;
///     return "Hi!";
///   }
///
///   void tryAgain() {
///     done = false;
///     greeting = new Future<String>.delayed(_delay, greet);
///   }
/// }
///
/// @Component(
///     selector: 'async-time',
///     template: "<p>Time: {{ $pipe.date($pipe.async(time), 'mediumTime') }}</p>") //
/// class AsyncTimePipe {
///   static const _delay = const Duration(seconds: 1);
///   final Stream<DateTime> time =
///       new Stream.periodic(_delay, (_) => new DateTime.now());
/// }
/// ```
///
@Pipe('async', pure: false)
class AsyncPipe implements OnDestroy {
  Object? _latestValue;
  Object? _subscription;
  dynamic /* Stream | Future | EventEmitter */ _obj;
  dynamic _strategy;
  final ChangeDetectorRef _ref;

  AsyncPipe(this._ref);

  @override
  void ngOnDestroy() {
    if (_subscription != null) {
      _dispose();
    }
  }

  dynamic transform(dynamic /* Stream | Future | EventEmitter */ obj) {
    if (_obj == null) {
      if (obj != null) {
        _subscribe(obj);
      }
    } else if (!_maybeStreamIdentical(obj, _obj)) {
      _dispose();
      return transform(obj);
    }
    return _latestValue;
  }

  void _subscribe(dynamic /* Stream | Future | EventEmitter */ obj) {
    _obj = obj;
    _strategy = _selectStrategy(obj);
    _subscription = _strategy.createSubscription(
        obj, (Object? value) => _updateLatestValue(obj, value));
  }

  dynamic _selectStrategy(dynamic /* Stream | Future | EventEmitter */ obj) {
    if (obj is Future<Object?>) {
      return _promiseStrategy;
    } else if (obj is Stream<Object?>) {
      return _observableStrategy;
    } else {
      throw InvalidPipeArgumentException(AsyncPipe, obj);
    }
  }

  void _dispose() {
    _strategy.dispose(_subscription);
    _latestValue = null;
    _subscription = null;
    _obj = null;
  }

  void _updateLatestValue(dynamic async, Object? value) {
    if (identical(async, _obj)) {
      _latestValue = value;
      _ref.markForCheck();
    }
  }

  // StreamController.stream getter always returns new Stream instance,
  // operator== check is also needed. See
  // https://github.com/angulardart/angular/issues/260
  static bool _maybeStreamIdentical(a, b) {
    if (!identical(a, b)) {
      return a is Stream<Object?> && b is Stream<Object?> && a == b;
    }
    return true;
  }
}
