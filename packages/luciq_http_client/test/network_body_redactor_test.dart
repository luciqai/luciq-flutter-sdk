import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_http_client/src/network_body_redactor.dart';

void main() {
  group('redactNetworkBody', () {
    test('redacts the personal fields of a customer response', () {
      final body = redactNetworkBody(<String, dynamic>{
        'data': <String, dynamic>{
          'customerId': 123456,
          'customerReference': 'HF-123456',
          'firstName': 'Ada',
          'lastName': 'Lovelace',
          'email': 'ada@example.com',
          'mobilePhone': '+447911123456',
          'birthDate': '1815-12-10',
        },
      });

      expect(body, contains('"firstName":"***REDACTED***"'));
      expect(body, contains('"lastName":"***REDACTED***"'));
      expect(body, contains('"email":"***REDACTED***"'));
      expect(body, contains('"mobilePhone":"***REDACTED***"'));
      expect(body, contains('"birthDate":"***REDACTED***"'));
      expect(body, isNot(contains('Ada')));
      expect(body, isNot(contains('Lovelace')));
      expect(body, isNot(contains('ada@example.com')));
      expect(body, isNot(contains('1815-12-10')));
    });

    test('keeps the fields that are needed for debugging', () {
      final body = redactNetworkBody(<String, dynamic>{
        'data': <String, dynamic>{
          'customerId': 123456,
          'customerReference': 'HF-123456',
          'tags': <String>['students'],
          'walletMinutes': 30,
          'isBlocked': false,
        },
      });

      expect(body, contains('"customerId":123456'));
      expect(body, contains('"customerReference":"HF-123456"'));
      expect(body, contains('"tags":["students"]'));
      expect(body, contains('"walletMinutes":30'));
      expect(body, contains('"isBlocked":false'));
    });

    // RIDER-5636
    test('redacts age and gender', () {
      final body = redactNetworkBody(<String, dynamic>{
        'data': <String, dynamic>{
          'rfm': 3,
          'segment': 'loyal',
          'age': 34,
          'gender': 'female',
          'subscription_id': 25,
        },
      });

      expect(body, contains('"age":"***REDACTED***"'));
      expect(body, contains('"gender":"***REDACTED***"'));
      expect(body, contains('"subscription_id":25'));
      expect(body, isNot(contains('"age":34')));
      expect(body, isNot(contains('female')));
    });

    // RIDER-5636
    test('redacts wunderTokenV3 and wunderTokenV4', () {
      final body = redactNetworkBody(<String, dynamic>{
        'data': <String, dynamic>{
          // Not JWT-shaped, so only the key-based rule catches this one.
          'wunderTokenV3': 'opaque-legacy-token-value',
          'wunderTokenV4': 'eyJhbGciOiJIUzI1NiJ9.fake.jwt',
        },
      });

      expect(body, contains('"wunderTokenV3":"***REDACTED***"'));
      expect(body, contains('"wunderTokenV4":"***REDACTED***"'));
    });

    // RIDER-5636
    test('redacts a verification code sent alongside a phone or email', () {
      final byPhone = redactNetworkBody(<String, dynamic>{
        'phone': '+447911123456',
        'code': '123456',
      });
      final byNumber = redactNetworkBody(<String, dynamic>{
        'number': '+447911123456',
        'code': '123456',
      });
      final byEmail = redactNetworkBody(<String, dynamic>{
        'email': 'ada@example.com',
        'code': '123456',
      });

      expect(byPhone, contains('"code":"***REDACTED***"'));
      expect(byNumber, contains('"code":"***REDACTED***"'));
      expect(byEmail, contains('"code":"***REDACTED***"'));
    });

    // RIDER-5636: `code` is also a plain plan/bundle identifier elsewhere in
    // this API, so it must only be redacted when it looks like a
    // verification code (paired with a phone or email), not on every
    // payload that happens to have a `code` field.
    test('does not redact a plan code with no phone or email alongside it',
        () {
      final body = redactNetworkBody(<String, dynamic>{
        'data': <String, dynamic>{
          'subscriptions': <Map<String, dynamic>>[
            <String, dynamic>{'code': '25', 'title': 'Forest Flex'},
          ],
        },
      });

      expect(body, contains('"code":"25"'));
    });

    test('redacts snake_case and alternative date-of-birth keys', () {
      final body = redactNetworkBody(<String, dynamic>{
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'date_of_birth': '1815-12-10',
        'birthday': '1815-12-10',
      });

      expect(body, contains('"first_name":"***REDACTED***"'));
      expect(body, contains('"last_name":"***REDACTED***"'));
      expect(body, contains('"date_of_birth":"***REDACTED***"'));
      expect(body, contains('"birthday":"***REDACTED***"'));
    });

    test('does not redact keys that only share a word with a personal field',
        () {
      final body = redactNetworkBody(<String, dynamic>{
        'name': 'Bike 1234',
        'firstRideCompleted': true,
        'lastRideId': 987,
      });

      expect(body, contains('"name":"Bike 1234"'));
      expect(body, contains('"firstRideCompleted":true'));
      expect(body, contains('"lastRideId":987'));
    });

    test('redacts personal fields sent in a request body', () {
      final body = redactNetworkBody(
        '{"email":"ada@example.com","birthDate":"1815-12-10"}',
      );

      expect(body, contains('"email":"***REDACTED***"'));
      expect(body, contains('"birthDate":"***REDACTED***"'));
    });

    test('keeps redacting credentials and phone numbers', () {
      final body = redactNetworkBody(<String, dynamic>{
        'password': 'secret',
        'access_token': 'abc123',
        'phoneNumber': '+447911123456',
      });

      expect(body, contains('"password":"***REDACTED***"'));
      expect(body, contains('"access_token":"***REDACTED***"'));
      expect(body, contains('"phoneNumber":"***REDACTED***"'));
    });
  });
}
