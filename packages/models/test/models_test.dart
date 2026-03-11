import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  test('sms purpose mapping', () {
    expect(authSmsPurposeToWire(AuthSmsPurpose.register), 'REGISTER');
  });
}
