import 'package:flutter_test/flutter_test.dart';
import 'package:pillly/features/medications/domain/medication.dart';

void main() {
  group('Medication.parseCycleType', () {
    test('parses daily correctly', () {
      expect(Medication.parseCycleType('daily'), CycleType.daily);
    });

    test('parses weekly correctly', () {
      expect(Medication.parseCycleType('weekly'), CycleType.weekly);
    });

    test('parses interval correctly', () {
      expect(Medication.parseCycleType('interval'), CycleType.interval);
    });

    test('defaults to daily for unknown value', () {
      expect(Medication.parseCycleType('unknown'), CycleType.daily);
    });
  });

  group('Medication.fromMap', () {
    test('parses backend response with nested schedules', () {
      final map = {
        'id': 'med-uuid',
        'user_id': 'user-uuid',
        'name': 'Metformin',
        'dosage': '500.0',
        'is_active': true,
        'schedules': [
          {'scheduled_time': '08:00:00', 'cycle_type': 'daily'},
          {'scheduled_time': '20:00:00', 'cycle_type': 'daily'},
        ],
      };

      final med = Medication.fromMap(map);

      expect(med.id, 'med-uuid');
      expect(med.name, 'Metformin');
      expect(med.cycleType, CycleType.daily);
      expect(med.scheduledTimes.length, 2);
      expect(med.scheduledTimes[0], '08:00');
      expect(med.scheduledTimes[1], '20:00');
      expect(med.isActive, true);
    });

    test('handles null dosage', () {
      final map = {
        'id': 'med-uuid',
        'user_id': 'user-uuid',
        'name': 'Vitamin C',
        'dosage': null,
        'is_active': true,
        'schedules': [
          {'scheduled_time': '09:00:00', 'cycle_type': 'daily'},
        ],
      };

      final med = Medication.fromMap(map);
      expect(med.dosage, isNull);
    });

    test('handles empty schedules array', () {
      final map = {
        'id': 'med-uuid',
        'user_id': 'user-uuid',
        'name': 'Test Med',
        'is_active': true,
        'schedules': [],
      };

      final med = Medication.fromMap(map);
      expect(med.scheduledTimes, isEmpty);
    });

    test('defaults isActive to true when missing', () {
      final map = {
        'id': 'med-uuid',
        'user_id': 'user-uuid',
        'name': 'Test Med',
        'schedules': [],
      };

      final med = Medication.fromMap(map);
      expect(med.isActive, true);
    });
  });

  group('Medication.copyWith', () {
    final medication = Medication(
      id: 'med-uuid',
      userId: 'user-uuid',
      name: 'Metformin',
      cycleType: CycleType.daily,
      scheduledTimes: ['08:00'],
      isActive: true,
    );

    test('updates isActive only', () {
      final updated = medication.copyWith(isActive: false);
      expect(updated.isActive, false);
      expect(updated.name, 'Metformin');
    });

    test('updates name only', () {
      final updated = medication.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.isActive, true);
    });
  });

  group('MedicationCreateRequest.toMap', () {
    test('builds daily schedule correctly', () {
      const request = MedicationCreateRequest(
        name: 'Metformin',
        cycleType: CycleType.daily,
        scheduledTimes: ['08:00', '20:00'],
        dosage: 500,
        unit: 'mg',
      );

      final map = request.toMap();

      expect(map['name'], 'Metformin');
      expect(map['schedules'], isA<List>());
      expect((map['schedules'] as List).length, 2);
      expect((map['schedules'] as List)[0]['scheduled_time'], '08:00');
      expect((map['schedules'] as List)[0]['cycle_type'], 'daily');
    });

    test('builds weekly schedule with weekdays', () {
      const request = MedicationCreateRequest(
        name: 'Aspirin',
        cycleType: CycleType.weekly,
        scheduledTimes: ['09:00'],
        weekdays: [1, 3, 5],
      );

      final map = request.toMap();
      final schedules = map['schedules'] as List;

      expect(schedules[0]['cycle_type'], 'weekly');
      expect(schedules[0]['cycle_value']['weekdays'], [1, 3, 5]);
    });

    test('builds interval schedule with interval_days', () {
      const request = MedicationCreateRequest(
        name: 'Vitamin D',
        cycleType: CycleType.interval,
        scheduledTimes: ['08:00'],
        intervalDays: 3,
      );

      final map = request.toMap();
      final schedules = map['schedules'] as List;

      expect(schedules[0]['cycle_type'], 'interval');
      expect(schedules[0]['cycle_value']['interval_days'], 3);
    });

    test('excludes null optional fields', () {
      const request = MedicationCreateRequest(
        name: 'Test Med',
        cycleType: CycleType.daily,
        scheduledTimes: ['08:00'],
      );

      final map = request.toMap();

      expect(map.containsKey('dosage'), false);
      expect(map.containsKey('memo'), false);
    });
  });
}
