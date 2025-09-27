// callback_screen.dart
import 'package:flutter/material.dart';
import 'package:luciq_flutter_example/src/screens/callback/callback_handler_provider.dart';
import 'package:provider/provider.dart';

class CallbackScreen extends StatelessWidget {
  static var screenName = "/callback";

  const CallbackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final handlers = context.watch<CallbackHandlersProvider>().callbackHandlers;
    final titles = handlers.keys.toList();

    return DefaultTabController(
      length: titles.isEmpty ? 1 : titles.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Callback Handlers"),
          bottom: TabBar(
            isScrollable: true,
            tabs: titles.isEmpty
                ? [const Tab(text: "No Data")]
                : titles.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: TabBarView(
          children: titles.isEmpty
              ? [
                  const Center(child: Text("No callback handlers yet")),
                ]
              : titles.map((title) {
                  return CallBackTabScreen(title: title);
                }).toList(),
        ),
      ),
    );
  }
}

class CallBackTabScreen extends StatelessWidget {
  final String title;
  const CallBackTabScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CallbackHandlersProvider>();
    final items = provider.callbackHandlers[title] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Items: ${items.length}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => provider.clearList(title),
                child: const Text(
                  "Clear Data",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("No items"))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.fields.map((field) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Force separate semantics for key
                                    Semantics(
                                      container: true,
                                      label: "field-key-${field.key}",
                                      child: ExcludeSemantics(
                                        child: Text(
                                          field.key,
                                          key:
                                              ValueKey("fieldKey_${field.key}"),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Force separate semantics for value
                                    Semantics(
                                      container: true,
                                      label: "field-value-${field.key}",
                                      child: ExcludeSemantics(
                                        child: Text(
                                          field.value,
                                          key: ValueKey(
                                              "fieldValue_${field.key}"),
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
