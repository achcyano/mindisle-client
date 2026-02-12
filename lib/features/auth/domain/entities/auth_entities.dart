import 'package:mindisle_client/shared/session/session_models.dart';

enum AuthLoginDecision {
  registerRequired,
  directLoginAllowed,
  passwordRequired,
}

final class LoginCheckResult {
  const LoginCheckResult({
    required this.decision,
    this.ticket,
  });

  final AuthLoginDecision decision;
  final String? ticket;
}

final class AuthSessionResult {
  const AuthSessionResult({
    required this.userId,
    required this.tokenPair,
  });

  final int userId;
  final TokenPair tokenPair;
}

enum SmsPurpose {
  register,
  resetPassword,
}
