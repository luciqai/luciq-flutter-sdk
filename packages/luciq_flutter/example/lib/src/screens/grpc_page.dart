part of '../../main.dart';

class GrpcPage extends StatefulWidget {
  static const screenName = 'grpc';

  const GrpcPage({Key? key}) : super(key: key);

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
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
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
    _setStatus('$label: running…');
    final startedAt = DateTime.now();
    await LuciqLog.logInfo(
      'gRPC → $path '
      'request=${jsonEncode(request)} startedAt=${startedAt.toIso8601String()}',
    );

    try {
      final response = await body();
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      const okHttp = 200;
      await LuciqLog.logInfo(
        'gRPC ✓ $path '
        'status=OK(0)→http$okHttp '
        'duration=${durationMs}ms '
        'response=${jsonEncode(response ?? '')}',
      );
      _setStatus('$label: ok ($durationMs ms)');
    } on GrpcError catch (e) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      final httpStatus = grpcStatusToHttpStatus(e.code);
      await LuciqLog.logError(
        'gRPC ✕ $path '
        'status=${e.codeName}(${e.code})→http$httpStatus '
        'duration=${durationMs}ms '
        'errorDomain=grpc '
        'message=${jsonEncode(e.message ?? e.codeName)}',
      );
      _setStatus('$label: grpc ${e.codeName} (${e.code})');
    } catch (e) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      await LuciqLog.logError(
        'gRPC ✕ $path '
        'status=unknown→http500 '
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
        body: () => _client.streamAborted('abort-me').toList().then(
              (chunks) => 'received ${chunks.length} chunks before abort',
            ),
      );

  Future<void> _streamCancel() => _run(
        'StreamCancel',
        path: '/luciq.Echo/BidiStream',
        request: '["one","two","three"]',
        body: () async {
          final call =
              _client.bidiStream(Stream.fromIterable(['one', 'two', 'three']));
          final sub = call.listen((_) {}, onError: (_) {});
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await call.cancel();
          await sub.cancel();
          await LuciqLog.logWarn(
            'gRPC client cancelled bidi stream after 50ms — '
            'interceptor will log CANCELLED(1)→http499',
          );
          return 'cancelled by client';
        },
      );

  @override
  Widget build(BuildContext context) {
    return Page(
      title: 'gRPC',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            _serverReady ? _status : 'Starting echo server…',
            key: const Key('grpc_status_text'),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        LuciqButton(
          text: 'Unary — Success',
          symanticLabel: 'make_grpc_unary_request',
          onPressed: _unaryEcho,
        ),
        LuciqButton(
          text: 'Unary — Not Found (404)',
          symanticLabel: 'make_grpc_unary_not_found',
          onPressed: _unaryNotFound,
        ),
        LuciqButton(
          text: 'Unary — Unauthenticated (401)',
          symanticLabel: 'make_grpc_unary_unauthenticated',
          onPressed: _unaryUnauthenticated,
        ),
        LuciqButton(
          text: 'Unary — Unavailable (503)',
          symanticLabel: 'make_grpc_unary_unavailable',
          onPressed: _unaryUnavailable,
        ),
        LuciqButton(
          text: 'Unary — Invalid Argument (400)',
          symanticLabel: 'make_grpc_unary_invalid_argument',
          onPressed: _unaryInvalidArgument,
        ),
        LuciqButton(
          text: 'Unary — Internal (500)',
          symanticLabel: 'make_grpc_unary_internal',
          onPressed: _unaryInternal,
        ),
        LuciqButton(
          text: 'Unary — Deadline Exceeded (504)',
          symanticLabel: 'make_grpc_unary_deadline_exceeded',
          onPressed: _unaryDeadline,
        ),
        LuciqButton(
          text: 'Unary — With caller traceparent',
          symanticLabel: 'make_grpc_unary_with_traceparent',
          onPressed: _unaryWithTraceparent,
        ),
        LuciqButton(
          text: 'Unary — Generated traceparent',
          symanticLabel: 'make_grpc_unary_without_traceparent',
          onPressed: _unaryWithoutTraceparent,
        ),
        LuciqButton(
          text: 'Server Streaming',
          symanticLabel: 'make_grpc_server_stream',
          onPressed: _serverStream,
        ),
        LuciqButton(
          text: 'Client Streaming',
          symanticLabel: 'make_grpc_client_stream',
          onPressed: _clientStream,
        ),
        LuciqButton(
          text: 'Bidirectional Streaming',
          symanticLabel: 'make_grpc_bidi_stream',
          onPressed: _bidiStream,
        ),
        LuciqButton(
          text: 'Stream — Server Aborted',
          symanticLabel: 'make_grpc_stream_error',
          onPressed: _streamAborted,
        ),
        LuciqButton(
          text: 'Stream — Client Cancel',
          symanticLabel: 'make_grpc_stream_cancel',
          onPressed: _streamCancel,
        ),
        SizedBox.fromSize(size: const Size.fromHeight(12)),
      ],
    );
  }
}
