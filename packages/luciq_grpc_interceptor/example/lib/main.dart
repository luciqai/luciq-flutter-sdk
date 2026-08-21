import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';

import 'grpc_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Luciq.init(
    token: '0174a800719ebdebf7b248fa6ae2ef17',
    invocationEvents: [InvocationEvent.floatingButton],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'luciq_grpc_interceptor example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GrpcPage(),
    );
  }
}
