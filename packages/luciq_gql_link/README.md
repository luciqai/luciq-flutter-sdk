# Luciq GraphQL Link

[![pub package](https://img.shields.io/pub/v/luciq_gql_link.svg)](https://pub.dev/packages/luciq_gql_link)

This package is an add on to [Luciq-Flutter](https://github.com/luciqai/luciq-flutter-sdk).

It intercepts any GraphQL operations performed with the `gql` package and sends them to the report
that will be sent to the dashboard.

## Integration

To enable network logging for GraphQL, add the `LuciqGqlLink` to your link chain:

```dart

final link = Link.from([
  LuciqGqlLink(endpoint: 'https://api.example.com/graphql'),
  HttpLink('https://api.example.com/graphql'),
]);
```

> **Placement matters.** `LuciqGqlLink` must come **before** the terminating link in
`Link.from([...])`. If it is placed after the terminator, it never runs.

> **`endpoint` is a display label**, not the transport URL. The actual request goes to whatever URL
> the terminating link is configured with. For dashboard correlation, pass the same URL to both.

## Coverage

`LuciqGqlLink` works with any client that uses the [`gql_link`](https://pub.dev/packages/gql_link)
middleware abstraction. That covers the majority of Flutter GraphQL apps:

| Client / link                                        | Captured by `LuciqGqlLink`?                     |
|------------------------------------------------------|-------------------------------------------------|
| `graphql` / `graphql_flutter`                        | Yes                                             |
| `ferry`                                              | Yes                                             |
| `artemis`                                            | Yes                                             |
| Custom `Link.from([...])` chains                     | Yes                                             |
| `gql_websocket_link` (subscriptions)                 | Yes — each emission is logged as its own record |
| `gql_dio_link` (multipart uploads)                   | Yes — files are logged as metadata placeholders |
| `hasura_connect` and other non-`gql` clients         | **No**                                          |
| Hand-rolled `http`/`dio` calls to a GraphQL endpoint | **No**                                          |

For traffic that is not built on `gql_link`, install the transport-layer interceptors instead (or in
addition):

- [`luciq_http_client`](https://pub.dev/packages/luciq_http_client) for code that uses
  `package:http`
- [`luciq_dio_interceptor`](https://pub.dev/packages/luciq_dio_interceptor) for code that uses
  `package:dio`

The two layers are complementary: `LuciqGqlLink` provides GraphQL semantics (operation name, type,
parsed errors), while the HTTP-level interceptors provide transport coverage for traffic that
bypasses `gql_link`.

## What gets captured

For every operation that flows through `LuciqGqlLink`, the dashboard sees:

- Operation name, operation type (`query` / `mutation` / `subscription`), and full request body
  (query document, `operationName`, sanitized variables).
- HTTP transport details when the terminating link is HTTP: status code, response headers,
  response body, content-type, and request/response byte sizes.
- A first-class `errorName` field populated from the first GraphQL error message (e.g.
  `"User not found"`) when the response carries `errors`, or from the Dart runtime type of the
  thrown exception on transport failure. This makes dashboard grouping by error work even when
  the HTTP status is `200`.
- `errorDomain = 'graphql'` on transport errors, plus the original response body / headers
  extracted from `HttpLinkServerException` and `HttpLinkParserException`.
- W3C `traceparent` correlation: the link injects a generated `traceparent` into the outgoing
  request, or preserves a caller-supplied one. The same value is recorded on the dashboard.
- Each subscription event is captured as its own record; the record `startTime` advances to the
  previous event's end, so the `duration` field reflects the inter-event gap.

### Multipart uploads

Variables that include `http.MultipartFile` (the shape used by `gql_http_link` and `gql_dio_link`
for `multipart/form-data` GraphQL uploads) are not consumed for logging — the terminating link
still gets the original file stream. In the captured request body, each `MultipartFile` is
replaced with a JSON-friendly placeholder so the operation can still be encoded:

```json
{
  "__luciq_multipart": true,
  "field": "avatar",
  "filename": "a.txt",
  "contentType": "text/plain; charset=utf-8",
  "length": 11
}
```

The walk is recursive: maps and lists nested inside `variables` are traversed.

## Diagnostic logging

`LuciqGqlLink` writes diagnostics through the same `dart:developer` logger the rest of the SDK
uses, gated by the level you pass to `Luciq.init`:

```dart
await
Luciq.init
(
token: '<APP_TOKEN>',
invocationEvents: [InvocationEvent.shake],
debugLogsLevel: LogLevel.debug, // or LogLevel.verbose for the full trace
);
```

What you'll see, by level (tag: `LuciqGqlLink`):

- `error` — `forward` placement mistakes, transport errors (with `runtimeType` and resolved HTTP
  status), request- or response-body encoding fallbacks.
- `debug` — per-operation entry (type, name, url) and per-response summary (HTTP status, number
  of GraphQL errors, microsecond duration). Subscriptions log once per emitted event.
- `verbose` — `endpoint` set at construction, W3C trace decisions (generated vs. inbound),
  body-size encoding fallbacks.

Production default is `LogLevel.error`, so only the actionable lines surface unless you opt in.
