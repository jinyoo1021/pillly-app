import 'package:flutter_test/flutter_test.dart';
import 'package:pillly/features/dose/domain/dose_stats.dart';

void main() {
  group('MedicationStat', () {
    test('fromMap parses correctly', () {
      final map = {
        'medication_name': 'Metformin',
        'rate': 85,
        'color_tag': '#1D9E75',
      };

      final stat = MedicationStat.fromMap(map);

      expect(stat.medicationName, 'Metformin');
      expect(stat.rate, 85);
      expect(stat.colorTag, '#1D9E75');
    });

    test('fromMap handles missing fields with defaults', () {
      final stat = MedicationStat.fromMap({});

      expect(stat.medicationName, '');
      expect(stat.rate, 0);
      expect(stat.colorTag, isNull);
    });
  });

  group('DoseStats', () {
    test('fromMap parses week period correctly', () {
      final map = {
        'period': 'week',
        'overall_rate': 75,
        'by_medication': [
          {'medication_name': 'Metformin', 'rate': 85, 'color_tag': '#1D9E75'},
          {'medication_name': 'Omega 3', 'rate': 60, 'color_tag': '#1D9E75'},
        ],
      };

      final stats = DoseStats.fromMap(map);

      expect(stats.period, 'week');
      expect(stats.overallRate, 75);
      expect(stats.byMedication.length, 2);
      expect(stats.byMedication[0].medicationName, 'Metformin');
      expect(stats.byMedication[0].rate, 85);
    });

    test('fromMap parses month period correctly', () {
      final map = {
        'period': 'month',
        'overall_rate': 90,
        'by_medication': [
          {'medication_name': 'Aspirin', 'rate': 90},
        ],
      };

      final stats = DoseStats.fromMap(map);

      expect(stats.period, 'month');
      expect(stats.overallRate, 90);
      expect(stats.byMedication.length, 1);
    });

    test('fromMap handles empty by_medication', () {
      final map = {
        'period': 'week',
        'overall_rate': 0,
        'by_medication': [],
      };

      final stats = DoseStats.fromMap(map);

      expect(stats.byMedication, isEmpty);
      expect(stats.overallRate, 0);
    });

    test('fromMap handles missing fields with defaults', () {
      final stats = DoseStats.fromMap({});

      expect(stats.period, 'week');
      expect(stats.overallRate, 0);
      expect(stats.byMedication, isEmpty);
    });
  });
}
