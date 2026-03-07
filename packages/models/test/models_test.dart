import 'package:models/models.dart';
import 'package:test/test.dart';

void main() {
  test('sms purpose mapping', () {
    expect(smsPurposeToWire(SmsPurpose.register), 'REGISTER');
  });
}

