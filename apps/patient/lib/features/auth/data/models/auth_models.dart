import 'package:models/models.dart' as shared;
import 'package:patient/features/auth/domain/entities/auth_entities.dart';

String smsPurposeToWire(SmsPurpose purpose) =>
    shared.authSmsPurposeToWire(purpose);

AuthLoginDecision loginDecisionFromWire(String raw) =>
    shared.authLoginDecisionFromWire(raw);

typedef SendSmsCodeRequest = shared.SendSmsCodePayload;
typedef RegisterRequest = shared.RegisterPayload;
typedef LoginCheckRequest = shared.LoginCheckPayload;
typedef DirectLoginRequest = shared.DirectLoginPayload;
typedef PasswordLoginRequest = shared.PasswordLoginPayload;
typedef TokenRefreshRequest = shared.TokenRefreshPayload;
typedef ResetPasswordRequest = shared.ResetPasswordPayload;
typedef LogoutRequest = shared.LogoutPayload;
typedef TokenPairDto = shared.TokenPairDto;
typedef AuthResponseDto = shared.AuthSessionResponseDto;
typedef LoginCheckResponseDto = shared.AuthLoginCheckResponseDto;
