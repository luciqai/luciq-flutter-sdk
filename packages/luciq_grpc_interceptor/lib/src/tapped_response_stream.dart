import 'dart:async';

import 'package:async/async.dart';
import 'package:grpc/grpc.dart';

/// Wraps a [ResponseStream] so the interceptor can observe consumer
/// cancellation (which the grpc package does not expose as a future).
class TappedResponseStream<R> extends StreamView<R>
    implements ResponseStream<R> {
  factory TappedResponseStream(
    ResponseStream<R> inner,
    Stream<R> tapped, {
    void Function()? onCancel,
  }) {
    final notifier = _CancelNotifier(onCancel);
    final controller = StreamController<R>(sync: true);
    StreamSubscription<R>? sub;
    var drained = false;
    controller
      ..onListen = () {
        sub = tapped.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            drained = true;
            controller.close();
          },
        );
      }
      ..onPause = () {
        sub?.pause();
      }
      ..onResume = () {
        sub?.resume();
      }
      ..onCancel = () async {
        if (!drained) notifier.fire();
        await sub?.cancel();
      };
    return TappedResponseStream._(inner, controller.stream, notifier);
  }

  TappedResponseStream._(this._inner, Stream<R> source, this._onCancel)
      : super(source);

  final ResponseStream<R> _inner;
  final _CancelNotifier _onCancel;

  @override
  Future<Map<String, String>> get headers => _inner.headers;

  @override
  Future<Map<String, String>> get trailers => _inner.trailers;

  @override
  Future<void> cancel() {
    _onCancel.fire();
    return _inner.cancel();
  }

  @override
  ResponseFuture<R> get single =>
      _TappedResponseFuture<R>(_inner, super.single);
}

class _TappedResponseFuture<R> extends DelegatingFuture<R>
    implements ResponseFuture<R> {
  _TappedResponseFuture(this._inner, Future<R> future) : super(future);

  final ResponseStream<R> _inner;

  @override
  Future<Map<String, String>> get headers => _inner.headers;

  @override
  Future<Map<String, String>> get trailers => _inner.trailers;

  @override
  Future<void> cancel() => _inner.cancel();
}

class _CancelNotifier {
  _CancelNotifier(this._callback);

  final void Function()? _callback;
  bool _fired = false;

  void fire() {
    if (_fired) return;
    _fired = true;
    _callback?.call();
  }
}
