import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/utils/luciq_utils.dart';

void main() {
  group('redactUrlForLog', () {
    test('returns empty for null', () {
      expect(redactUrlForLog(null), '');
    });
    test('returns empty for empty', () {
      expect(redactUrlForLog(''), '');
    });
    test('returns URL unchanged when no query or fragment', () {
      expect(
        redactUrlForLog('https://api.example.com/users/123'),
        'https://api.example.com/users/123',
      );
      expect(
        redactUrlForLog('http://localhost:8081/symbolicate'),
        'http://localhost:8081/symbolicate',
      );
    });
    test('strips simple query and appends marker', () {
      expect(
        redactUrlForLog('https://api.example.com/users?email=u@x.com'),
        'https://api.example.com/users?<redacted>',
      );
    });
    test('strips multi-parameter query', () {
      expect(
        redactUrlForLog(
          'https://api.example.com/auth?token=abc&user=12345&hash=xyz',
        ),
        'https://api.example.com/auth?<redacted>',
      );
    });
    test('strips trailing question mark', () {
      expect(
        redactUrlForLog('https://api.example.com/users?'),
        'https://api.example.com/users?<redacted>',
      );
    });
    test('never leaks sensitive query value', () {
      const sensitive = 'super-secret-token-value-9876';
      final out =
          redactUrlForLog('https://api.example.com/users?token=$sensitive');
      expect(out.contains(sensitive), isFalse);
      expect(out.contains('token='), isFalse);
    });
    test('strips fragment silently when no query present', () {
      expect(
        redactUrlForLog('https://app.example.com/page#section-2'),
        'https://app.example.com/page',
      );
    });
    test('strips fragment with sensitive data', () {
      final out =
          redactUrlForLog('https://app.example.com/page#access_token=abc');
      expect(out, 'https://app.example.com/page');
      expect(out.contains('abc'), isFalse);
      expect(out.contains('access_token'), isFalse);
    });
    test('cuts at query when query comes first', () {
      expect(
        redactUrlForLog('https://api.example.com/users?email=u@x.com#anchor'),
        'https://api.example.com/users?<redacted>',
      );
    });
    test('cuts at fragment when fragment comes first', () {
      expect(
        redactUrlForLog('https://app.example.com/page#frag?fake'),
        'https://app.example.com/page',
      );
    });
    test('strips user:password@ from authority', () {
      expect(
        redactUrlForLog('https://user:pass@api.example.com/users/123'),
        'https://api.example.com/users/123',
      );
    });
    test('strips username-only userinfo', () {
      expect(
        redactUrlForLog('https://alice@api.example.com/users'),
        'https://api.example.com/users',
      );
    });
    test('never leaks password component', () {
      const secret = 'p@ssw0rd-do-not-leak';
      final out = redactUrlForLog('https://user:$secret@api.example.com/x');
      expect(out.contains(secret), isFalse);
      expect(out.contains('user:'), isFalse);
    });
    test('strips userinfo and query together', () {
      expect(
        redactUrlForLog('https://u:p@api.example.com/users?token=abc'),
        'https://api.example.com/users?<redacted>',
      );
    });
    test('does not strip an @ that appears in the path', () {
      expect(
        redactUrlForLog('https://api.example.com/users/@me/profile'),
        'https://api.example.com/users/@me/profile',
      );
    });
    test('no-op when no scheme separator is present', () {
      expect(redactUrlForLog('user@host/path'), 'user@host/path');
    });
    test('regression: never emits a query "=" or fragment "#"', () {
      const inputs = [
        'https://x.com/p?a=1',
        'https://x.com/p?a=1&b=2',
        'https://x.com/p#frag',
        'https://x.com/p?a=1#frag',
        'http://localhost:1234/foo?bar=baz',
      ];
      for (final url in inputs) {
        final out = redactUrlForLog(url);
        expect(out.contains('='), isFalse, reason: url);
        expect(out.contains('#'), isFalse, reason: url);
      }
    });
  });
}
