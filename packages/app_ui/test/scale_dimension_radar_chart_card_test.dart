import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('radar chips show normalized display value with two decimals', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: ScaleDimensionRadarChartCard(
            entries: [
              ScaleRadarDimensionEntry(
                label: '躯体化',
                value: 1.17,
                displayValue: 1.17,
                maxValue: 5,
              ),
              ScaleRadarDimensionEntry(
                label: '强迫',
                value: 1.35,
                displayValue: 1.35,
                maxValue: 5,
              ),
              ScaleRadarDimensionEntry(
                label: '抑郁',
                value: 1.88,
                displayValue: 1.88,
                maxValue: 5,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('躯体化 1.17'), findsOneWidget);
    expect(find.text('强迫 1.35'), findsOneWidget);
    expect(find.text('抑郁 1.88'), findsOneWidget);
  });
}
