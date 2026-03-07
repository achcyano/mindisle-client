import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('result success stores data', () {
    const result = Success<int>(1);
    expect(result.data, 1);
  });
}
