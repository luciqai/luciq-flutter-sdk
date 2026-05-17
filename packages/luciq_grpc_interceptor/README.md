# Luciq gRPC Interceptor

[![pub package](https://img.shields.io/pub/v/luciq_grpc_interceptor.svg)](https://pub.dev/packages/luciq_grpc_interceptor)

This package is an add on to [Luciq-Flutter](https://github.com/luciqai/luciq-flutter-sdk).

It intercepts gRPC calls performed with the `grpc` package and forwards them to the Luciq dashboard
alongside HTTP traffic captured by the rest of the SDK.

## Integration

Add the `LuciqGrpcInterceptor` to your generated client's interceptors:

```dart
final channel = ClientChannel(
  'localhost',
  port: 50051,
  options: ChannelOptions(credentials: ChannelCredentials.insecure()),
);

final client = GreeterClient(
  channel,
  interceptors: [LuciqGrpcInterceptor()],
);
```

The same interceptor handles unary calls and all three streaming RPC kinds (server-, client-, and
bidirectional-streaming):

```dart

final stream = client.subscribeUpdates(SubscribeRequest(...));
await for (
final update in stream) { ... }
```

## What gets logged

For every RPC the dashboard receives:

- **URL** of the form `grpc://<authority><method.path>` so calls to different backends can be told
  apart.
- **Request and response bodies**, serialized via `toProto3Json()` for protobuf messages and via
  `jsonEncode` for plain Dart objects. For streaming RPCs, every message in both directions is
  captured up to a 64 KiB in-memory buffer per call (see "Limits" below).
- **Request metadata** (auth tokens, custom keys, the injected W3C `traceparent`).
- **Initial headers and trailers** (trailers prefixed with `trailer-` to disambiguate).
- **Status**: gRPC status codes are mapped to HTTP-equivalent codes via `grpcStatusToHttpStatus`.
  Non-OK statuses surface `errorDomain: 'grpc'`, the original gRPC code in `errorCode`, and the
  status name (e.g. `NOT_FOUND`, `UNAVAILABLE`, `CANCELLED`) in `errorName` for dashboard grouping.
- **Cancellation**: streams cancelled by the consumer before trailers arrive are logged as
  `CANCELLED` (HTTP 499, gRPC code 1) with whatever request/response messages were captured up to
  the cancellation point.
- **Stream metrics**: `x-luciq-stream-message-count`, `x-luciq-stream-first-byte-ms`, and
  `x-luciq-stream-last-byte-ms` are added to the response headers map for streaming calls.
- **Distributed tracing**: a W3C `traceparent` is generated and attached to outbound metadata when
  the SDK's W3C feature flag is enabled.

## Debug logging

The interceptor emits structured logs via the SDK's internal `LuciqLogger` under the tag
`LuciqGrpcInterceptor`. Logs are gated by the SDK's log level (set via `Luciq.setSdkLogLevel`):

- `debug`: call lifecycle (start, success, failure, cancellation, trailer-status non-OK).
- `error`: callback failures, W3C provider failures, and any internal logging failure.
- `verbose`: per-call W3C details and best-effort header/trailer fetch failures.

Raising the log level to `debug` is the recommended way to diagnose missing or misshapen dashboard
records in production builds.

## Limits

- Each streaming call accumulates at most 64 KiB of message bodies in memory before truncating; the
  dashboard's global body-size limit (configurable from the Luciq backend) still applies on top.
- Bodies are best-effort serialized: protobuf messages use `toProto3Json`, anything else falls back
  to `jsonEncode` then `toString`.
