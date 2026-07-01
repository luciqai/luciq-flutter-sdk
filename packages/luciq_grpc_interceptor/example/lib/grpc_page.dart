import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_grpc_interceptor/luciq_grpc_interceptor.dart';

import 'echo_client.dart';
import 'echo_server.dart';

class GrpcPage extends StatefulWidget {
  const GrpcPage({super.key});

  @override
  State<GrpcPage> createState() => _GrpcPageState();
}

class _GrpcPageState extends State<GrpcPage> {
  late final ClientChannel _channel;
  late final EchoClient _client;
  String _status = 'Idle';
  bool _serverReady = false;

  @override
  void initState() {
    super.initState();
    _channel = ClientChannel(
      kEchoServiceHost,
      port: kEchoServicePort,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    _client = EchoClient(_channel, interceptors: [LuciqGrpcInterceptor()]);
    _ensureServer();
  }

  Future<void> _ensureServer() async {
    try {
      await ensureEchoServerStarted();
      if (mounted) setState(() => _serverReady = true);
    } catch (e) {
      if (mounted) setState(() => _status = 'Server start failed: $e');
    }
  }

  @override
  void dispose() {
    _channel.shutdown();
    super.dispose();
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }

  Future<void> _run(
    String label, {
    required String path,
    required String request,
    required Future<String?> Function() body,
  }) async {
    _setStatus('$label: running...');
    final startedAt = DateTime.now();
    await LuciqLog.logInfo(
      'gRPC -> $path '
      'request=${jsonEncode(request)} startedAt=${startedAt.toIso8601String()}',
    );

    try {
      final response = await body();
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      const okHttp = 200;
      await LuciqLog.logInfo(
        'gRPC OK $path '
        'status=OK(0)->http$okHttp '
        'duration=${durationMs}ms '
        'response=${jsonEncode(response ?? '')}',
      );
      _setStatus('$label: ok ($durationMs ms)');
    } on GrpcError catch (e) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      final httpStatus = grpcStatusToHttpStatus(e.code);
      await LuciqLog.logError(
        'gRPC FAIL $path '
        'status=${e.codeName}(${e.code})->http$httpStatus '
        'duration=${durationMs}ms '
        'errorDomain=grpc '
        'message=${jsonEncode(e.message ?? e.codeName)}',
      );
      _setStatus('$label: grpc ${e.codeName} (${e.code})');
    } catch (e) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      await LuciqLog.logError(
        'gRPC FAIL $path '
        'status=unknown->http500 '
        'duration=${durationMs}ms '
        'error=${jsonEncode(e.toString())}',
      );
      _setStatus('$label: error $e');
    }
  }

  Future<void> _unaryEcho() => _run(
    'UnaryEcho',
    path: '/luciq.Echo/UnaryEcho',
    request: 'hello',
    body: () => _client.unaryEcho('hello'),
  );

  Future<void> _unaryNotFound() => _run(
    'UnaryNotFound',
    path: '/luciq.Echo/UnaryNotFound',
    request: 'missing',
    body: () => _client.unaryNotFound('missing'),
  );

  Future<void> _unaryUnauthenticated() => _run(
    'UnaryUnauthenticated',
    path: '/luciq.Echo/UnaryUnauthenticated',
    request: 'no-token',
    body: () => _client.unaryUnauthenticated('no-token'),
  );

  Future<void> _unaryUnavailable() => _run(
    'UnaryUnavailable',
    path: '/luciq.Echo/UnaryUnavailable',
    request: 'down',
    body: () => _client.unaryUnavailable('down'),
  );

  Future<void> _unaryInvalidArgument() => _run(
    'UnaryInvalidArgument',
    path: '/luciq.Echo/UnaryInvalidArgument',
    request: 'bad',
    body: () => _client.unaryInvalidArgument('bad'),
  );

  Future<void> _unaryInternal() => _run(
    'UnaryInternal',
    path: '/luciq.Echo/UnaryInternal',
    request: 'boom',
    body: () => _client.unaryInternal('boom'),
  );

  Future<void> _unaryDeadline() => _run(
    'UnaryDeadline',
    path: '/luciq.Echo/UnaryDeadline',
    request: 'slow',
    body: () => _client.unaryDeadline(
      'slow',
      timeout: const Duration(milliseconds: 300),
    ),
  );

  Future<void> _unaryWithTraceparent() => _run(
    'UnaryWithTraceparent',
    path: '/luciq.Echo/UnaryEcho',
    request: 'with-traceparent',
    body: () async {
      const traceparent =
          '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01';
      await LuciqLog.logVerbose(
        'gRPC traceparent metadata supplied by caller: $traceparent',
      );
      return _client.unaryEcho(
        'with-traceparent',
        options: CallOptions(metadata: {'traceparent': traceparent}),
      );
    },
  );

  Future<void> _unaryWithoutTraceparent() => _run(
    'UnaryWithoutTraceparent',
    path: '/luciq.Echo/UnaryEcho',
    request: 'no-traceparent',
    body: () async {
      await LuciqLog.logVerbose(
        'gRPC no caller metadata; interceptor will generate traceparent',
      );
      return _client.unaryEcho('no-traceparent');
    },
  );

  Future<void> _serverStream() => _run(
    'ServerStream',
    path: '/luciq.Echo/ServerStream',
    request: 'stream-me',
    body: () async {
      final chunks = await _client.serverStream('stream-me').toList();
      await LuciqLog.logVerbose(
        'gRPC server-stream received ${chunks.length} chunks: '
        '${jsonEncode(chunks)}',
      );
      return 'received ${chunks.length} chunks';
    },
  );

  Future<void> _clientStream() => _run(
    'ClientStream',
    path: '/luciq.Echo/ClientStream',
    request: '["a","b","c"]',
    body: () => _client.clientStream(Stream.fromIterable(['a', 'b', 'c'])),
  );

  Future<void> _bidiStream() => _run(
    'BidiStream',
    path: '/luciq.Echo/BidiStream',
    request: '["one","two","three"]',
    body: () async {
      final responses = await _client
          .bidiStream(Stream.fromIterable(['one', 'two', 'three']))
          .toList();
      await LuciqLog.logVerbose(
        'gRPC bidi exchanged ${responses.length} messages: '
        '${jsonEncode(responses)}',
      );
      return 'echoed ${responses.length} messages';
    },
  );

  Future<void> _streamAborted() => _run(
    'StreamAborted',
    path: '/luciq.Echo/StreamAborted',
    request: 'abort-me',
    body: () => _client
        .streamAborted('abort-me')
        .toList()
        .then((chunks) => 'received ${chunks.length} chunks before abort'),
  );

  Future<void> _streamCancel() => _run(
    'StreamCancel',
    path: '/luciq.Echo/BidiStream',
    request: '["one","two","three"]',
    body: () async {
      final call = _client.bidiStream(
        Stream.fromIterable(['one', 'two', 'three']),
      );
      final sub = call.listen((_) {}, onError: (_) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await call.cancel();
      await sub.cancel();
      await LuciqLog.logWarn(
        'gRPC client cancelled bidi stream after 50ms - '
        'interceptor will log CANCELLED(1)->http499',
      );
      return 'cancelled by client';
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('gRPC')),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                _serverReady ? _status : 'Starting echo server...',
                key: const Key('grpc_status_text'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            _DemoButton(text: 'Unary - Success', onPressed: _unaryEcho),
            _DemoButton(
              text: 'Unary - Not Found (404)',
              onPressed: _unaryNotFound,
            ),
            _DemoButton(
              text: 'Unary - Unauthenticated (401)',
              onPressed: _unaryUnauthenticated,
            ),
            _DemoButton(
              text: 'Unary - Unavailable (503)',
              onPressed: _unaryUnavailable,
            ),
            _DemoButton(
              text: 'Unary - Invalid Argument (400)',
              onPressed: _unaryInvalidArgument,
            ),
            _DemoButton(
              text: 'Unary - Internal (500)',
              onPressed: _unaryInternal,
            ),
            _DemoButton(
              text: 'Unary - Deadline Exceeded (504)',
              onPressed: _unaryDeadline,
            ),
            _DemoButton(
              text: 'Unary - With caller traceparent',
              onPressed: _unaryWithTraceparent,
            ),
            _DemoButton(
              text: 'Unary - Generated traceparent',
              onPressed: _unaryWithoutTraceparent,
            ),
            _DemoButton(text: 'Server Streaming', onPressed: _serverStream),
            _DemoButton(text: 'Client Streaming', onPressed: _clientStream),
            _DemoButton(
              text: 'Bidirectional Streaming',
              onPressed: _bidiStream,
            ),
            _DemoButton(
              text: 'Stream - Server Aborted',
              onPressed: _streamAborted,
            ),
            _DemoButton(
              text: 'Stream - Client Cancel',
              onPressed: _streamCancel,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.text, this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
