typedef DeviceIdAttachRule = bool Function(String path);

final class NetworkAuthStrategy {
  NetworkAuthStrategy({
    required this.authPathPrefix,
    required Set<String> publicPaths,
    required this.refreshPath,
    this.unauthorizedBusinessCode = 40100,
    this.principalIdKeys = const <String>['userId'],
    this.expiredMessage = '登录状态已过期，请重新登录',
    this.deviceIdAttachRule,
  }) : publicPaths = Set<String>.from(publicPaths);

  final String authPathPrefix;
  final Set<String> publicPaths;
  final String refreshPath;
  final int unauthorizedBusinessCode;
  final List<String> principalIdKeys;
  final String expiredMessage;
  final DeviceIdAttachRule? deviceIdAttachRule;

  bool isPublicPath(String path) => publicPaths.contains(path);

  bool shouldAttachDeviceId(String path) {
    final custom = deviceIdAttachRule;
    if (custom != null) return custom(path);
    return path.startsWith(authPathPrefix);
  }
}
