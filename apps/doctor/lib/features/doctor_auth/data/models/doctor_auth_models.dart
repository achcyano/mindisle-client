import 'package:doctor/features/doctor_auth/domain/entities/doctor_auth_entities.dart';
import 'package:models/models.dart' as shared;

String doctorSmsPurposeToWire(DoctorSmsPurpose purpose) =>
    shared.authSmsPurposeToWire(purpose);

DoctorAuthLoginDecision doctorLoginDecisionFromWire(String raw) =>
    shared.authLoginDecisionFromWire(raw);

typedef DoctorSendSmsCodeRequest = shared.SendSmsCodePayload;
typedef DoctorRegisterRequest = shared.RegisterPayload;
typedef DoctorLoginCheckRequest = shared.LoginCheckPayload;
typedef DoctorDirectLoginRequest = shared.DirectLoginPayload;
typedef DoctorPasswordLoginRequest = shared.PasswordLoginPayload;
typedef DoctorTokenRefreshRequest = shared.TokenRefreshPayload;
typedef DoctorResetPasswordRequest = shared.ResetPasswordPayload;
typedef DoctorChangePasswordRequest = shared.ChangePasswordPayload;
typedef DoctorLogoutRequest = shared.LogoutPayload;
typedef DoctorTokenPairDto = shared.TokenPairDto;
typedef DoctorAuthResponseDto = shared.AuthSessionResponseDto;
typedef DoctorLoginCheckResponseDto = shared.AuthLoginCheckResponseDto;
