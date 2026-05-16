import 'package:flutter_test/flutter_test.dart';
import 'package:patient/view/pages/scale/scale_webview_url.dart';

void main() {
  group('buildScaleWebViewUri', () {
    test('builds TESS entry uri with access token fragment', () {
      final uri = buildScaleWebViewUri(
        baseUrl: 'https://example.com:8888',
        webPath: '/web/scales/TESS',
        accessToken: 'token-123',
      );

      expect(uri.toString(), 'https://example.com:8888/web/scales/TESS#accessToken=token-123');
    });

    test('preserves sessionId query and encodes token fragment', () {
      final uri = buildScaleWebViewUri(
        baseUrl: 'https://example.com:8888',
        webPath: '/web/scales/TESS?sessionId=99',
        accessToken: 'token value+1',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'example.com');
      expect(uri.path, '/web/scales/TESS');
      expect(uri.queryParameters['sessionId'], '99');
      expect(uri.fragment, 'accessToken=token+value%2B1');
    });

    test('rejects non scale web path', () {
      expect(
        () => buildScaleWebViewUri(
          baseUrl: 'https://example.com:8888',
          webPath: '/api/v1/scales',
          accessToken: 'token',
        ),
        throwsA(isA<ScaleWebViewUriException>()),
      );
    });

    test('rejects absolute web path', () {
      expect(
        () => buildScaleWebViewUri(
          baseUrl: 'https://example.com:8888',
          webPath: 'https://evil.example/web/scales/TESS',
          accessToken: 'token',
        ),
        throwsA(isA<ScaleWebViewUriException>()),
      );
    });
  });
}
