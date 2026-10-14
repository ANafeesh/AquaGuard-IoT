import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquaguard/features/history/widgets/fl_parameter_chart.dart';
import 'package:aquaguard/models/measurement.dart';

void main() {
  testWidgets('FlParameterChart renders title, range selector, and data points', (WidgetTester tester) async {
    String currentRange = '24h';
    final points = [
      HistoricalPoint('00:00', 7.1),
      HistoricalPoint('06:00', 7.2),
      HistoricalPoint('12:00', 7.4),
      HistoricalPoint('18:00', 7.3),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return FlParameterChart(
                title: 'pH Indicator Trend',
                parameterName: 'pH',
                unit: '',
                points: points,
                selectedRange: currentRange,
                onRangeChanged: (newRange) {
                  setState(() => currentRange = newRange);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('pH Indicator Trend'), findsOneWidget);
    expect(find.textContaining('Tap any data point to inspect'), findsOneWidget);

    // Verify Range Filter Pills
    expect(find.text('24h'), findsOneWidget);
    expect(find.text('7d'), findsOneWidget);
    expect(find.text('30d'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Tap range pill '7d' and verify callback
    await tester.tap(find.text('7d'));
    await tester.pumpAndSettle();
    expect(currentRange, '7d');
  });

  testWidgets('FlParameterChart displays empty state when points list is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlParameterChart(
            title: 'TDS Indicator Trend',
            parameterName: 'TDS',
            unit: 'ppm',
            points: const [],
            selectedRange: '30d',
            onRangeChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify empty range state message is displayed
    expect(find.text('No data for this range'), findsOneWidget);
  });
}
