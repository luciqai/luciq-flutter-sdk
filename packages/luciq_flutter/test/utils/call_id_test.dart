import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/utils/call_id.dart';

void main() {
  group('CallId', () {
    setUp(CallId.resetForTest);

    test('produces 4-char lowercase hex strings', () {
      final id = CallId.next();
      expect(id.length, 4);
      expect(RegExp(r'^[0-9a-f]{4}$').hasMatch(id), isTrue);
    });

    test('produces sequential ids', () {
      expect(CallId.next(), '0000');
      expect(CallId.next(), '0001');
      expect(CallId.next(), '0002');
    });

    test('wraps at 0xFFFF', () {
      for (var i = 0; i < 0xFFFF; i++) {
        CallId.next();
      }
      expect(CallId.next(), 'ffff');
      expect(CallId.next(), '0000');
    });
  });
}
