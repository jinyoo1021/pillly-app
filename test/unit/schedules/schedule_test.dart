import 'package:flutter_test/flutter_test.dart';
import 'package:pillly/features/schedules/domain/schedule.dart';

void main() {
  group('TodaySchedule.parseStatus', () {
    test('parses done', () {
      expect(TodaySchedule.parseStatus('done'), DoseStatus.done);
    });

    test('parses skipped', () {
      expect(TodaySchedule.parseStatus('skipped'), DoseStatus.skipped);
    });

    test('parses missed', () {
      expect(TodaySchedule.parseStatus('missed'), DoseStatus.missed);
    });

    test('parses pending', () {
      expect(TodaySchedule.parseStatus('pending'), DoseStatus.pending);
    });

    test('defaults to pending for unknown value', () {
      expect(TodaySchedule.parseStatus('unknown'), DoseStatus.pending);
    });
  });

  group('TodaySchedule.fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'schedule_id': 'sched-uuid',
        'medication_id': 'med-uuid',
        'medication_name': 'Aspirin',
        'scheduled_time': '08:00',
        'status': 'pending',
        'dosage': 100.0,
        'unit': 'mg',
      };

      final schedule = TodaySchedule.fromMap(map);

      expect(schedule.scheduleId, 'sched-uuid');
      expect(schedule.medicationName, 'Aspirin');
      expect(schedule.scheduledTime, '08:00');
      expect(schedule.status, DoseStatus.pending);
      expect(schedule.dosage, 100.0);
      expect(schedule.unit, 'mg');
    });

    test('handles missing optional fields', () {
      final map = {
        'schedule_id': 'sched-uuid',
        'medication_id': '',
        'medication_name': 'Test Med',
        'scheduled_time': '08:00',
        'status': 'pending',
      };

      final schedule = TodaySchedule.fromMap(map);

      expect(schedule.dosage, isNull);
      expect(schedule.unit, isNull);
      expect(schedule.doseLogId, isNull);
    });

    test('defaults status to pending when null', () {
      final map = {
        'schedule_id': 'sched-uuid',
        'medication_id': '',
        'medication_name': 'Test',
        'scheduled_time': '08:00',
        'status': null,
      };

      final schedule = TodaySchedule.fromMap(map);
      expect(schedule.status, DoseStatus.pending);
    });
  });

  group('TodaySchedule.copyWith', () {
    final schedule = TodaySchedule(
      scheduleId: 'sched-uuid',
      medicationId: 'med-uuid',
      medicationName: 'Aspirin',
      scheduledTime: '08:00',
      status: DoseStatus.pending,
    );

    test('updates status to done', () {
      final updated = schedule.copyWith(status: DoseStatus.done);
      expect(updated.status, DoseStatus.done);
      expect(updated.scheduleId, 'sched-uuid');
    });

    test('updates doseLogId', () {
      final updated = schedule.copyWith(doseLogId: 'log-uuid');
      expect(updated.doseLogId, 'log-uuid');
      expect(updated.status, DoseStatus.pending);
    });
  });

  group('DoseStatus', () {
    test('has exactly 4 statuses', () {
      expect(DoseStatus.values.length, 4);
    });

    test('contains all expected statuses', () {
      expect(DoseStatus.values, containsAll([
        DoseStatus.pending,
        DoseStatus.done,
        DoseStatus.skipped,
        DoseStatus.missed,
      ]));
    });
  });
}
