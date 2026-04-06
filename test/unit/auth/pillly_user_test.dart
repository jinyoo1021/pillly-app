import 'package:flutter_test/flutter_test.dart';
import 'package:pillly/features/auth/domain/pillly_user.dart';

void main() {
  group('PilllyUser', () {
    test('fromMap creates user correctly', () {
      final map = {
        'id': 'user-uuid',
        'email': 'test@pillly.com',
        'name': 'Test User',
        'language': 'en',
        'timezone': 'Asia/Seoul',
      };

      final user = PilllyUser.fromMap(map);

      expect(user.id, 'user-uuid');
      expect(user.email, 'test@pillly.com');
      expect(user.name, 'Test User');
      expect(user.language, 'en');
      expect(user.timezone, 'Asia/Seoul');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 'user-uuid',
        'email': 'test@pillly.com',
      };

      final user = PilllyUser.fromMap(map);

      expect(user.id, 'user-uuid');
      expect(user.name, isNull);
      expect(user.language, isNull);
      expect(user.timezone, isNull);
    });

    test('copyWith updates only specified fields', () {
      const user = PilllyUser(
        id: 'user-uuid',
        email: 'test@pillly.com',
        name: 'Old Name',
      );

      final updated = user.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(updated.id, 'user-uuid');
      expect(updated.email, 'test@pillly.com');
    });

    test('toMap excludes null optional fields', () {
      const user = PilllyUser(
        id: 'user-uuid',
        email: 'test@pillly.com',
      );

      final map = user.toMap();

      expect(map['id'], 'user-uuid');
      expect(map['email'], 'test@pillly.com');
      expect(map.containsKey('name'), false);
      expect(map.containsKey('language'), false);
    });

    test('toMap includes all fields when present', () {
      const user = PilllyUser(
        id: 'user-uuid',
        email: 'test@pillly.com',
        name: 'Test User',
        language: 'en',
        timezone: 'Asia/Seoul',
      );

      final map = user.toMap();

      expect(map['name'], 'Test User');
      expect(map['language'], 'en');
      expect(map['timezone'], 'Asia/Seoul');
    });
  });
}
