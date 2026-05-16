import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient/core/providers/app_providers.dart';
import 'package:patient/view/pages/scale/scale_webview_args.dart';
import 'package:patient/view/pages/scale/scale_webview_url.dart';
import 'package:patient/view/route/app_route.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ScaleWebViewPage extends ConsumerStatefulWidget {
  const ScaleWebViewPage({super.key, required this.args});

  final ScaleWebViewArgs args;

  static final route = AppRouteArg<void, ScaleWebViewArgs>(
    path: '/home/scale/webview',
    builder: (args) => ScaleWebViewPage(args: args),
  );

  @override
  ConsumerState<ScaleWebViewPage> createState() => _ScaleWebViewPageState();
}

class _ScaleWebViewPageState extends ConsumerState<ScaleWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final token = await ref.read(sessionStoreProvider).readAccessToken();
    if (!mounted) return;

    if (token == null || token.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = '缺少访问令牌，请重新登录后再试';
      });
      return;
    }

    late final Uri uri;
    try {
      uri = buildScaleWebViewUri(
        baseUrl: ref.read(appConfigProvider).baseUrl,
        webPath: widget.args.webPath,
        accessToken: token,
      );
    } on ScaleWebViewUriException catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
      return;
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = '量表页面地址无效';
      });
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _isLoading = false;
              _errorMessage = error.description.isEmpty
                  ? '量表页面加载失败，请稍后重试'
                  : error.description;
            });
          },
          onNavigationRequest: (request) {
            final nextUri = Uri.tryParse(request.url);
            if (nextUri == null) return NavigationDecision.prevent;
            if (nextUri.scheme != uri.scheme || nextUri.host != uri.host) {
              return NavigationDecision.prevent;
            }
            if (!nextUri.path.startsWith('/web/scales/') &&
                !nextUri.path.startsWith('/api/v1/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(uri);

    setState(() {
      _controller = controller;
      _isLoading = true;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.args.title.trim().isEmpty
        ? '量表评估'
        : widget.args.title.trim();
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (controller != null && _errorMessage == null)
              WebViewWidget(controller: controller),
            if (_errorMessage != null)
              _ScaleWebViewError(
                message: _errorMessage!,
                onRetry: _initialize,
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicatorM3E()),
          ],
        ),
      ),
    );
  }
}

class _ScaleWebViewError extends StatelessWidget {
  const _ScaleWebViewError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
