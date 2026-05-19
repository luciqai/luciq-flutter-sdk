import 'dart:async';
import 'dart:convert';

import 'package:grpc/grpc.dart';

ClientMethod<String, String> _stringMethod(String path) =>
    ClientMethod<String, String>(path, utf8.encode, utf8.decode);

class EchoClient extends Client {
  static final _unaryEcho = _stringMethod('/luciq.Echo/UnaryEcho');
  static final _unaryNotFound = _stringMethod('/luciq.Echo/UnaryNotFound');
  static final _unaryUnauthenticated = _stringMethod(
    '/luciq.Echo/UnaryUnauthenticated',
  );
  static final _unaryUnavailable = _stringMethod(
    '/luciq.Echo/UnaryUnavailable',
  );
  static final _unaryInvalidArgument = _stringMethod(
    '/luciq.Echo/UnaryInvalidArgument',
  );
  static final _unaryInternal = _stringMethod('/luciq.Echo/UnaryInternal');
  static final _unaryDeadline = _stringMethod('/luciq.Echo/UnaryDeadline');
  static final _serverStream = _stringMethod('/luciq.Echo/ServerStream');
  static final _clientStream = _stringMethod('/luciq.Echo/ClientStream');
  static final _bidiStream = _stringMethod('/luciq.Echo/BidiStream');
  static final _streamAborted = _stringMethod('/luciq.Echo/StreamAborted');

  EchoClient(super.channel, {super.options, super.interceptors});

  ResponseFuture<String> unaryEcho(String message, {CallOptions? options}) =>
      $createUnaryCall(_unaryEcho, message, options: options);

  ResponseFuture<String> unaryNotFound(String message) =>
      $createUnaryCall(_unaryNotFound, message);

  ResponseFuture<String> unaryUnauthenticated(String message) =>
      $createUnaryCall(_unaryUnauthenticated, message);

  ResponseFuture<String> unaryUnavailable(String message) =>
      $createUnaryCall(_unaryUnavailable, message);

  ResponseFuture<String> unaryInvalidArgument(String message) =>
      $createUnaryCall(_unaryInvalidArgument, message);

  ResponseFuture<String> unaryInternal(String message) =>
      $createUnaryCall(_unaryInternal, message);

  ResponseFuture<String> unaryDeadline(
    String message, {
    Duration timeout = const Duration(milliseconds: 500),
  }) => $createUnaryCall(
    _unaryDeadline,
    message,
    options: CallOptions(timeout: timeout),
  );

  ResponseStream<String> serverStream(String message) =>
      $createStreamingCall(_serverStream, Stream.value(message));

  Future<String> clientStream(Stream<String> messages) =>
      $createStreamingCall(_clientStream, messages).single;

  ResponseStream<String> bidiStream(Stream<String> messages) =>
      $createStreamingCall(_bidiStream, messages);

  ResponseStream<String> streamAborted(String message) =>
      $createStreamingCall(_streamAborted, Stream.value(message));
}
