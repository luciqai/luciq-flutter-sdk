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
| `gql_dio_link` (multipart uploads)                   | Yes                                             |
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
