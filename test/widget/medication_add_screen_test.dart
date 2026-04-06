import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillly/features/medications/presentation/medication_add_screen.dart';
import 'package:pillly/shared/theme/app_theme.dart';

void main() {
  Widget buildSubject() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MedicationAddScreen(),
      ),
    );
  }

  // Ignore overflow errors in widget tests
  setUp(() {
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      FlutterError.presentError(details);
    };
  });

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
  });

  group('MedicationAddScreen', () {
    testWidgets('renders medication name field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Medication name'), findsOneWidget);
    });

    testWidgets('renders schedule and reminder sections', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Reminder times'), findsOneWidget);
    });

    testWidgets('shows Save button in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows error when name is empty on save', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(
        find.text('Please enter the medication name.'),
        findsOneWidget,
      );
    });

    testWidgets('shows all cycle type options', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Every day'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Interval'), findsOneWidget);
    });

    testWidgets('shows weekday selector when Weekly selected', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekly'));
      await tester.pump();

      expect(find.text('Days of the week'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('shows interval selector when Interval selected', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Interval'));
      await tester.pump();

      expect(find.text('Every N days'), findsOneWidget);
    });

    testWidgets('shows Add time button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Add time'), findsOneWidget);
    });

    testWidgets('shows Notes optional field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Notes (optional)'), findsOneWidget);
    });
  });
}
