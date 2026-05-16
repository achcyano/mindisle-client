Uri buildScaleWebViewUri({
  required String baseUrl,
  required String webPath,
  required String accessToken,
}) {
  final token = accessToken.trim();
  if (token.isEmpty) {
    throw const ScaleWebViewUriException('缺少访问令牌，请重新登录后再试');
  }

  final path = webPath.trim();
  final pathUri = Uri.tryParse(path);
  if (pathUri == null ||
      pathUri.hasScheme ||
      pathUri.hasAuthority ||
      pathUri.path.isEmpty ||
      !pathUri.path.startsWith('/web/scales/')) {
    throw const ScaleWebViewUriException('量表页面地址无效');
  }

  final base = Uri.parse(baseUrl);
  if (!base.hasScheme || base.host.isEmpty) {
    throw const ScaleWebViewUriException('服务器地址配置无效');
  }

  return base.replace(
    path: pathUri.path,
    queryParameters: pathUri.hasQuery ? pathUri.queryParameters : null,
    fragment: Uri(queryParameters: <String, String>{
      'accessToken': token,
    }).query,
  );
}

final class ScaleWebViewUriException implements Exception {
  const ScaleWebViewUriException(this.message);

  final String message;

  @override
  String toString() => message;
}
