import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_gql_link/luciq_gql_link.dart';

const _kGqlHttpEndpoint = 'https://graphqlzero.almansi.me/api';
const _kGqlWsEndpoint = 'wss://realtime-chat.hasura.app/v1/graphql';
const _kGqlBadHostEndpoint =
    'https://does-not-exist.luciq-example.invalid/graphql';

class GraphQLPage extends StatefulWidget {
  const GraphQLPage({super.key});

  @override
  State<GraphQLPage> createState() => _GraphQLPageState();
}

class _GraphQLPageState extends State<GraphQLPage> {
  late final GraphQLClient _client;
  late final GraphQLClient _badHostClient;
  StreamSubscription<QueryResult<Object?>>? _subscription;
  String _status = 'Idle';
  int _subscriptionEvents = 0;

  @override
  void initState() {
    super.initState();

    final httpLink = HttpLink(_kGqlHttpEndpoint);
    final wsLink = WebSocketLink(
      _kGqlWsEndpoint,
      config: const SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: Duration(seconds: 30),
      ),
    );
    final terminatingLink = Link.split(
      (request) => request.isSubscription,
      wsLink,
      httpLink,
    );
    _client = GraphQLClient(
      link: Link.from([
        LuciqGqlLink(endpoint: _kGqlHttpEndpoint),
        terminatingLink,
      ]),
      cache: GraphQLCache(),
    );

    _badHostClient = GraphQLClient(
      link: Link.from([
        LuciqGqlLink(endpoint: _kGqlBadHostEndpoint),
        HttpLink(_kGqlBadHostEndpoint),
      ]),
      cache: GraphQLCache(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }

  Future<void> _run(
    String label, {
    required Future<String?> Function() body,
  }) async {
    _setStatus('$label: running...');
    final startedAt = DateTime.now();
    await LuciqLog.logInfo(
      'GraphQL -> $label startedAt=${startedAt.toIso8601String()}',
    );

    try {
      final detail = await body();
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      await LuciqLog.logInfo(
        'GraphQL OK $label duration=${durationMs}ms '
        'detail=${jsonEncode(detail ?? '')}',
      );
      _setStatus('$label: ok ($durationMs ms)');
    } on OperationException catch (e) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      final gqlErrors = e.graphqlErrors
          .map((err) => err.message)
          .toList(growable: false);
      await LuciqLog.logError(
        'GraphQL FAIL $label duration=${durationMs}ms '
        'errorDomain=graphql '
        'gqlErrors=${jsonEncode(gqlErrors)} '
        'linkException=${jsonEncode(e.linkException?.toString() ?? '')}',
      );
      _setStatus(
        '$label: gql error ${gqlErrors.isEmpty ? e.linkException : gqlErrors}',
      );
    } catch (e) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      await LuciqLog.logError(
        'GraphQL FAIL $label duration=${durationMs}ms '
        'error=${jsonEncode(e.toString())}',
      );
      _setStatus('$label: error $e');
    }
  }

  Future<QueryResult<Object?>> _query(
    GraphQLClient client,
    String document, {
    Map<String, dynamic> variables = const {},
    Map<String, String> headers = const {},
    String? operationName,
  }) {
    return client.query(
      QueryOptions(
        document: gql(document),
        variables: variables,
        operationName: operationName,
        fetchPolicy: FetchPolicy.networkOnly,
        context: headers.isEmpty
            ? const Context()
            : Context.fromList([HttpLinkHeaders(headers: headers)]),
      ),
    );
  }

  Future<QueryResult<Object?>> _mutate(
    String document, {
    Map<String, dynamic> variables = const {},
    String? operationName,
  }) {
    return _client.mutate(
      MutationOptions(
        document: gql(document),
        variables: variables,
        operationName: operationName,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
  }

  Future<void> _queryListPosts() => _run(
    'Query.listPosts',
    body: () async {
      const doc = r'''
            query ListPosts($options: PageQueryOptions) {
              posts(options: $options) {
                data { id title }
              }
            }
          ''';
      final result = await _query(
        _client,
        doc,
        operationName: 'ListPosts',
        variables: const {
          'options': {
            'paginate': {'page': 1, 'limit': 5},
          },
        },
      );
      if (result.hasException) throw result.exception!;
      final posts = (result.data?['posts']?['data'] as List?) ?? const [];
      return 'received ${posts.length} posts';
    },
  );

  Future<void> _queryPostById() => _run(
    'Query.postById',
    body: () async {
      const doc = r'''
            query PostById($id: ID!) {
              post(id: $id) { id title body }
            }
          ''';
      final result = await _query(
        _client,
        doc,
        operationName: 'PostById',
        variables: const {'id': '1'},
      );
      if (result.hasException) throw result.exception!;
      final title = result.data?['post']?['title'] as String?;
      return 'post#1 title="${title ?? ''}"';
    },
  );

  Future<void> _mutationCreatePost() => _run(
    'Mutation.createPost',
    body: () async {
      const doc = r'''
            mutation CreatePost($input: CreatePostInput!) {
              createPost(input: $input) { id title body }
            }
          ''';
      final result = await _mutate(
        doc,
        operationName: 'CreatePost',
        variables: const {
          'input': {
            'title': 'Luciq says hi',
            'body': 'Posted from luciq_gql_link example',
          },
        },
      );
      if (result.hasException) throw result.exception!;
      final id = result.data?['createPost']?['id']?.toString();
      return 'created post id=$id';
    },
  );

  Future<void> _queryWithTraceparent() => _run(
    'Query.withCallerTraceparent',
    body: () async {
      const traceparent =
          '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01';
      await LuciqLog.logVerbose(
        'GraphQL traceparent supplied by caller: $traceparent',
      );
      const doc = r'''
            query Tagged { post(id: "2") { id title } }
          ''';
      final result = await _query(
        _client,
        doc,
        operationName: 'Tagged',
        headers: const {'traceparent': traceparent},
      );
      if (result.hasException) throw result.exception!;
      return 'post#2 with caller traceparent';
    },
  );

  Future<void> _queryWithoutTraceparent() => _run(
    'Query.generatedTraceparent',
    body: () async {
      await LuciqLog.logVerbose(
        'GraphQL no caller traceparent; LuciqGqlLink will generate one',
      );
      const doc = r'''
            query Untagged { post(id: "3") { id title } }
          ''';
      final result = await _query(_client, doc, operationName: 'Untagged');
      if (result.hasException) throw result.exception!;
      return 'post#3 with generated traceparent';
    },
  );

  Future<void> _queryInvalidField() => _run(
    'Query.invalidField',
    body: () async {
      const doc = r'''
            query InvalidField { post(id: "1") { id thisFieldDoesNotExist } }
          ''';
      final result = await _query(_client, doc, operationName: 'InvalidField');
      if (result.hasException) throw result.exception!;
      return 'unexpected success';
    },
  );

  Future<void> _queryBadHost() => _run(
    'Query.badHost',
    body: () async {
      const doc = r'''
            query BadHost { post(id: "1") { id } }
          ''';
      final result = await _query(
        _badHostClient,
        doc,
        operationName: 'BadHost',
      );
      if (result.hasException) throw result.exception!;
      return 'unexpected success';
    },
  );

  Future<void> _subscribeOnlineUsers() => _run(
    'Subscription.onlineUsers',
    body: () async {
      await _subscription?.cancel();
      _subscriptionEvents = 0;
      const doc = r'''
            subscription OnlineUsers {
              user_online(order_by: { last_seen: desc }, limit: 10) {
                id username last_seen
              }
            }
          ''';
      final stream = _client.subscribe(
        SubscriptionOptions(
          document: gql(doc),
          operationName: 'OnlineUsers',
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      final completer = Completer<int>();
      _subscription = stream.listen(
        (result) {
          if (result.hasException) {
            if (!completer.isCompleted) {
              completer.completeError(result.exception!);
            }
            return;
          }
          _subscriptionEvents += 1;
          if (mounted) setState(() {});
          LuciqLog.logVerbose(
            'GraphQL subscription emission #$_subscriptionEvents '
            'data=${jsonEncode(result.data ?? {})}',
          );
        },
        onError: (Object error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(_subscriptionEvents);
          }
        },
      );

      // Wait for the first emission (or 5s) so the button gives the user
      // immediate feedback. The subscription itself keeps running in the
      // background until "Cancel subscription" is pressed.
      await Future.any<void>([
        Future<void>.delayed(const Duration(seconds: 5)),
        () async {
          while (_subscriptionEvents == 0 && _subscription != null) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }(),
      ]);

      if (completer.isCompleted) {
        // Surface the error captured above.
        throw await completer.future.then<Object>(
          (_) => 'completed',
          onError: (Object e) => e,
        );
      }

      return 'subscribed; received $_subscriptionEvents event(s) so far';
    },
  );

  Future<void> _cancelSubscription() async {
    final hadSub = _subscription != null;
    await _subscription?.cancel();
    _subscription = null;
    await LuciqLog.logInfo(
      'GraphQL subscription cancelled by client '
      '(events=$_subscriptionEvents)',
    );
    _setStatus(
      hadSub
          ? 'Subscription cancelled (events=$_subscriptionEvents)'
          : 'No active subscription',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GraphQL')),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                _status,
                key: const Key('graphql_status_text'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'HTTP: $_kGqlHttpEndpoint\nWS: $_kGqlWsEndpoint',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            _DemoButton(text: 'Query - list posts', onPressed: _queryListPosts),
            _DemoButton(
              text: 'Query - post by id (variables)',
              onPressed: _queryPostById,
            ),
            _DemoButton(
              text: 'Mutation - createPost',
              onPressed: _mutationCreatePost,
            ),
            _DemoButton(
              text: 'Query - caller traceparent',
              onPressed: _queryWithTraceparent,
            ),
            _DemoButton(
              text: 'Query - generated traceparent',
              onPressed: _queryWithoutTraceparent,
            ),
            _DemoButton(
              text: 'Query - invalid field (errors[])',
              onPressed: _queryInvalidField,
            ),
            _DemoButton(
              text: 'Query - bad host (network failure)',
              onPressed: _queryBadHost,
            ),
            _DemoButton(
              text: 'Subscription - online users',
              onPressed: _subscribeOnlineUsers,
            ),
            _DemoButton(
              text: 'Cancel subscription',
              onPressed: _cancelSubscription,
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
