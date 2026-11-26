import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caretrack/core/constants/app_strings.dart';
import 'package:caretrack/ui/widgets/status_badge.dart';
import 'package:caretrack/ui/widgets/stat_card.dart';

void main() {
  testWidgets('StatusBadge displays status label and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusBadge.forMedicineStatus('taken'),
        ),
      ),
    );

    expect(find.text('Taken'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('StatCard renders title, value and subtitle correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'Blood Pressure',
            value: '120/80 mmHg',
            subtitle: 'Normal',
            icon: Icons.favorite_rounded,
          ),
        ),
      ),
    );

    expect(find.text('Blood Pressure'), findsOneWidget);
    expect(find.text('120/80 mmHg'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  test('AppStrings contains CareTrack and Tagline', () {
    expect(AppStrings.appName, equals('CareTrack'));
    expect(AppStrings.appTagline, equals('Your Health, Your Responsibility'));
  });
}
