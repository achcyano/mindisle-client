import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Opens a web URL in the system browser (outside the app).
Future<bool> openInExternalBrowser(String url) async {
  final raw = url.trim();
  if (raw.isEmpty) return false;

  Uri? uri = Uri.tryParse(raw);
  if (uri != null && uri.scheme.isEmpty) {
    uri = Uri.tryParse('https://$raw');
  }
  if (uri == null) return false;

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) return true;
    return launchUrl(uri);
  } on PlatformException catch (error, stackTrace) {
    debugPrint('openInExternalBrowser PlatformException: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  } catch (error, stackTrace) {
    debugPrint('openInExternalBrowser error: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}
