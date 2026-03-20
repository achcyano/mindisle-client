import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RetryErrorCard renders content and triggers retry', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RetryErrorCard(
            title: '网络连接异常',
            message: '请检查网络后重试',
            onRetry: () {
              retryCount += 1;
            },
          ),
        ),
      ),
    );

    expect(find.text('网络连接异常'), findsOneWidget);
    expect(find.text('请检查网络后重试'), findsOneWidget);

    await tester.tap(find.byType(RetryErrorCard));
    await tester.pump();

    expect(retryCount, 1);
  });
}
