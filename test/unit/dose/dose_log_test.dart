import 'package:flutter_test/flutter_test.dart';
import 'package:pillly/features/dose/domain/dose_log.dart';
import 'package:pillly/features/schedules/domain/schedule.dart';
import 'package:pillly/features/dose/providers/dose_history_provider.dart';

void main() {
  group('DoseLog.fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'id': 'log-uuid',
        'schedule_id': 'sched-uuid',
        'medication_name': 'Aspirin',
        'log_date': '2026-04-02',
        'status': 'done',
        'scheduled_time': '08:00',
      };

      final log = DoseLog.fromMap(map);

      expect(log.id, 'log-uuid');
      expect(log.scheduleId, 'sched-uuid');
      expect(log.medicationName, 'Aspirin');
      expect(log.logDate, DateTime(2026, 4, 2));
      expect(log.status, DoseStatus.done);
      expect(log.scheduledTime, '08:00');
    });

    test('parses all DoseStatus values', () {
      for (final status in ['done', 'skipped', 'missed', 'pending']) {
        final map = {
          'id': 'log-uuid',
          'schedule_id': 'sched-uuid',
          'medication_name': 'Test',
          'log_date': '2026-04-02',
          'status': status,
        };

        final log = DoseLog.fromMap(map);
        expect(log.status.name, status);
      }
    });

    test('defaults unknown status to pending', () {
      final map = {
        'id': 'log-uuid',
        'schedule_id': 'sched-uuid',
        'medication_name': 'Test',
        'log_date': '2026-04-02',
        'status': 'unknown_status',
      };

      final log = DoseLog.fromMap(map);
      expect(log.status, DoseStatus.pending);
    });

    test('handles null takenAt', () {
      final map = {
        'id': 'log-uuid',
        'schedule_id': 'sched-uuid',
        'medication_name': 'Test',
        'log_date': '2026-04-02',
        'status': 'pending',
        'taken_at': null,
      };

      final log = DoseLog.fromMap(map);
      expect(log.takenAt, isNull);
    });
  });

  group('dayStatus', () {
    DoseLog makeLog(DoseStatus status) => DoseLog(
          id: 'log-uuid',
          scheduleId: 'sched-uuid',
          medicationName: 'Test Med',
          logDate: DateTime(2026, 4, 2),
          status: status,
        );

    test('returns null for empty log list', () {
      expect(dayStatus([]), isNull);
    });

    test('returns done when all logs are done', () {
      final logs = [
        makeLog(DoseStatus.done),
        makeLog(DoseStatus.done),
      ];
      expect(dayStatus(logs), DoseStatus.done);
    });

    test('returns missed when any log is missed (priority over done)', () {
      final logs = [
        makeLog(DoseStatus.done),
        makeLog(DoseStatus.missed),
      ];
      expect(dayStatus(logs), DoseStatus.missed);
    });

    test('returns pending when any log is pending', () {
      final logs = [
        makeLog(DoseStatus.done),
        makeLog(DoseStatus.pending),
      ];
      expect(dayStatus(logs), DoseStatus.pending);
    });

    test('returns skipped when all logs are skipped', () {
      final logs = [
        makeLog(DoseStatus.skipped),
        makeLog(DoseStatus.skipped),
      ];
      expect(dayStatus(logs), DoseStatus.skipped);
    });

    test('missed has higher priority than pending', () {
      final logs = [
        makeLog(DoseStatus.missed),
        makeLog(DoseStatus.pending),
      ];
      expect(dayStatus(logs), DoseStatus.missed);
    });
  });
}
