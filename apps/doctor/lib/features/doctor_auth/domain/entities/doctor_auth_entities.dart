import 'package:app_core/app_core.dart';

final class DoctorAuthSession {
  const DoctorAuthSession({
    required this.doctorId,
    required this.tokenPair,
  });

  final int doctorId;
  final TokenPair tokenPair;
}

enum DoctorSmsPurpose {
  register,
  resetPassword,
}

String doctorSmsPurposeToWire(DoctorSmsPurpose purpose) {
  return switch (purpose) {
    DoctorSmsPurpose.register => 'REGISTER',
    DoctorSmsPurpose.resetPassword => 'RESET_PASSWORD',
  };
}
