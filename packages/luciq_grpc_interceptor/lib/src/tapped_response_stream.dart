import 'dart:async';

import 'package:async/async.dart';
import 'package:grpc/grpc.dart';

class TappedResponseStream<R> extends StreamView<R>
    implements ResponseStream<R> {
  TappedResponseStream(this._inner, Stream<R> tapped) : super(tapped);

  final ResponseStream<R> _inner;

  @override
  Future<Map<String, String>> get headers => _inner.headers;

  @override
  Future<Map<String, String>> get trailers => _inner.trailers;

  @override
  Future<void> cancel() => _inner.cancel();

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
