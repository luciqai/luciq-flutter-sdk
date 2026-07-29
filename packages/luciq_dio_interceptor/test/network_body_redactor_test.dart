import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_dio_interceptor/luciq_dio_interceptor.dart';

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
          'gender': 1,
          'tags': <String>['students'],
          'walletMinutes': 30,
          'isBlocked': false,
        },
      });

      expect(body, contains('"customerId":123456'));
      expect(body, contains('"customerReference":"HF-123456"'));
      expect(body, contains('"gender":1'));
      expect(body, contains('"tags":["students"]'));
      expect(body, contains('"walletMinutes":30'));
      expect(body, contains('"isBlocked":false'));
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
