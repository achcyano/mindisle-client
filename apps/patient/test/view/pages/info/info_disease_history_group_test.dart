import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient/features/user/presentation/profile/profile_state.dart';
import 'package:patient/view/pages/info/info_disease_history_group.dart';

void main() {
  testWidgets('adds first disease history entry from empty state', (
    tester,
  ) async {
    String? changedValue;
    String? snackMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfoDiseaseHistoryGroup(
            state: const ProfileState(),
            onDiseaseHistoryChanged: (value) => changedValue = value,
            onShowSnack: (message) => snackMessage = message,
          ),
        ),
      ),
    );

    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('肠胃炎'));
    await tester.pumpAndSettle();

    expect(changedValue, '肠胃炎');
    expect(snackMessage, isNull);
  });
}
