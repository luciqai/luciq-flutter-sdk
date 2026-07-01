import 'dart:async';
import 'dart:convert';

import 'package:grpc/grpc.dart';

const String kEchoServiceHost = 'localhost';
const int kEchoServicePort = 50051;

class EchoService extends Service {
  @override
  String get $name => 'luciq.Echo';

  EchoService() {
    $addMethod(
      ServiceMethod<String, String>(
        'UnaryEcho',
        _unaryEcho,
        false,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'UnaryNotFound',
        _unaryNotFound,
        false,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'UnaryUnauthenticated',
        _unaryUnauthenticated,
        false,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'UnaryUnavailable',
        _unaryUnavailable,
        false,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'UnaryInvalidArgument',
        _unaryInvalidArgument,
        false,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'UnaryInternal',
        _unaryInternal,
        false,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'UnaryDeadline',
        _unaryDeadline,
        false,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'ServerStream',
        _serverStream,
        false,
        true,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'ClientStream',
        _clientStream,
        true,
        false,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'BidiStream',
        _bidiStream,
        true,
        true,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
    $addMethod(
      ServiceMethod<String, String>(
        'StreamAborted',
        _streamAborted,
        false,
        true,
        _stringFromBytes,
        _stringToBytes,
      ),
    );
  }

  Future<String> _unaryEcho(ServiceCall call, Future<String> request) async {
    final value = await request;
    return 'echo: $value';
  }

  Future<String> _unaryNotFound(
    ServiceCall call,
    Future<String> request,
  ) async {
    await request;
    throw const GrpcError.notFound('resource not found');
  }

  Future<String> _unaryUnauthenticated(
    ServiceCall call,
    Future<String> request,
  ) async {
    await request;
    throw const GrpcError.unauthenticated('missing credentials');
  }

  Future<String> _unaryUnavailable(
    ServiceCall call,
    Future<String> request,
  ) async {
    await request;
    throw const GrpcError.unavailable('service unavailable');
  }

  Future<String> _unaryInvalidArgument(
    ServiceCall call,
    Future<String> request,
  ) async {
    await request;
    throw const GrpcError.invalidArgument('invalid argument');
  }

  Future<String> _unaryInternal(
    ServiceCall call,
    Future<String> request,
  ) async {
    await request;
    throw const GrpcError.internal('internal server error');
  }

  Future<String> _unaryDeadline(
    ServiceCall call,
    Future<String> request,
  ) async {
    await request;
    await Future<void>.delayed(const Duration(seconds: 5));
    return 'too late';
  }

  Stream<String> _serverStream(
    ServiceCall call,
    Future<String> request,
  ) async* {
    final value = await request;
    for (var i = 1; i <= 3; i++) {
      yield 'chunk $i for $value';
    }
  }

  Future<String> _clientStream(
    ServiceCall call,
    Stream<String> requests,
  ) async {
    var count = 0;
    await for (final _ in requests) {
      count++;
    }
    return 'received $count messages';
  }

  Stream<String> _bidiStream(ServiceCall call, Stream<String> requests) async* {
    await for (final value in requests) {
      yield 'echo: $value';
    }
  }

  Stream<String> _streamAborted(
    ServiceCall call,
    Future<String> request,
  ) async* {
    await request;
    yield 'partial chunk';
    throw const GrpcError.aborted('stream aborted by server');
  }
}

String _stringFromBytes(List<int> bytes) => utf8.decode(bytes);

List<int> _stringToBytes(String value) => utf8.encode(value);

Future<Server> startEchoServer() async {
  final server = Server.create(services: [EchoService()]);
  await server.serve(address: kEchoServiceHost, port: kEchoServicePort);
  return server;
}

Future<Server>? _echoServerFuture;

Future<Server> ensureEchoServerStarted() {
  return _echoServerFuture ??= startEchoServer();
}
