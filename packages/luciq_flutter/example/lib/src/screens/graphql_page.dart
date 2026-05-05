part of '../../main.dart';

const _kGqlHttpEndpoint = 'https://graphqlzero.almansi.me/api';
const _kGqlWsEndpoint = 'wss://realtime-chat.hasura.app/v1/graphql';
const _kGqlBadHostEndpoint =
    'https://does-not-exist.luciq-example.invalid/graphql';

class GraphQLPage extends StatefulWidget {
  static const screenName = 'graphql';

  const GraphQLPage({Key? key}) : super(key: key);

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
    _setStatus('$label: running…');
    final startedAt = DateTime.now();
    await LuciqLog.logInfo(
      'GraphQL → $label startedAt=${startedAt.toIso8601String()}',
    );

    try {
      final detail = await body();
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      await LuciqLog.logInfo(
        'GraphQL ✓ $label duration=${durationMs}ms '
        'detail=${jsonEncode(detail ?? '')}',
      );
      _setStatus('$label: ok ($durationMs ms)');
    } on OperationException catch (e) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      final gqlErrors =
          e.graphqlErrors.map((err) => err.message).toList(growable: false);
      await LuciqLog.logError(
        'GraphQL ✕ $label duration=${durationMs}ms '
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
        'GraphQL ✕ $label duration=${durationMs}ms '
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
                'body': 'Posted from luciq_flutter example',
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
          final result = await _query(
            _client,
            doc,
            operationName: 'Untagged',
          );
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
          final result = await _query(
            _client,
            doc,
            operationName: 'InvalidField',
          );
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
              if (!completer.isCompleted)
                completer.complete(_subscriptionEvents);
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
            throw await completer.future
                .then<Object>((_) => 'completed', onError: (Object e) => e);
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
    return Page(
      title: 'GraphQL',
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
        LuciqButton(
          text: 'Query — list posts',
          symanticLabel: 'gql_query_list_posts',
          onPressed: _queryListPosts,
        ),
        LuciqButton(
          text: 'Query — post by id (variables)',
          symanticLabel: 'gql_query_post_by_id',
          onPressed: _queryPostById,
        ),
        LuciqButton(
          text: 'Mutation — createPost',
          symanticLabel: 'gql_mutation_create_post',
          onPressed: _mutationCreatePost,
        ),
        LuciqButton(
          text: 'Query — caller traceparent',
          symanticLabel: 'gql_query_with_traceparent',
          onPressed: _queryWithTraceparent,
        ),
        LuciqButton(
          text: 'Query — generated traceparent',
          symanticLabel: 'gql_query_without_traceparent',
          onPressed: _queryWithoutTraceparent,
        ),
        LuciqButton(
          text: 'Query — invalid field (errors[])',
          symanticLabel: 'gql_query_invalid_field',
          onPressed: _queryInvalidField,
        ),
        LuciqButton(
          text: 'Query — bad host (network failure)',
          symanticLabel: 'gql_query_bad_host',
          onPressed: _queryBadHost,
        ),
        LuciqButton(
          text: 'Subscription — online users',
          symanticLabel: 'gql_subscription_online_users',
          onPressed: _subscribeOnlineUsers,
        ),
        LuciqButton(
          text: 'Cancel subscription',
          symanticLabel: 'gql_subscription_cancel',
          onPressed: _cancelSubscription,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
