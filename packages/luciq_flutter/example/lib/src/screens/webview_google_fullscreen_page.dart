import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewGoogleFullscreenPage extends StatefulWidget {
  static const screenName = '/webview-google-fullscreen';

  const WebViewGoogleFullscreenPage({Key? key}) : super(key: key);

  @override
  State<WebViewGoogleFullscreenPage> createState() =>
      _WebViewGoogleFullscreenPageState();
}

class _WebViewGoogleFullscreenPageState
    extends State<WebViewGoogleFullscreenPage> {
  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onMenuSelected(_LuciqNetMenu item) async {
    switch (item) {
      case _LuciqNetMenu.autoMaskOn:
        await NetworkLogger.setNetworkAutoMaskingEnabled(true);
        _showSnack('Network auto-masking: ENABLED (applies to WebView)');
        break;
      case _LuciqNetMenu.autoMaskOff:
        await NetworkLogger.setNetworkAutoMaskingEnabled(false);
        _showSnack('Network auto-masking: DISABLED');
        break;
      case _LuciqNetMenu.bodyLogOn:
        await NetworkLogger.setNetworkLogBodyEnabled(true);
        _showSnack('Body logging: ENABLED');
        break;
      case _LuciqNetMenu.bodyLogOff:
        await NetworkLogger.setNetworkLogBodyEnabled(false);
        _showSnack('Body logging: DISABLED');
        break;
      case _LuciqNetMenu.obfuscateDart:
        NetworkLogger.obfuscateLog((data) async {
          // Redact sensitive-looking query/body; Dart-only — no effect on
          // the WebView's Fetch/XHR traffic.
          final masked = data.url.replaceAllMapped(
            RegExp(r'(token|api_key|password)=[^&]+', caseSensitive: false),
            (m) => '${m.group(1)}=[REDACTED]',
          );
          return data.copyWith(url: masked);
        });
        _showSnack('Dart obfuscate callback set (Dart HTTP only)');
        break;
      case _LuciqNetMenu.omitDart:
        NetworkLogger.omitLog((data) async {
          // Drop analytics-like URLs entirely; Dart-only.
          return data.url.contains('analytics') ||
              data.url.contains('googletagmanager');
        });
        _showSnack('Dart omit-log callback set (Dart HTTP only)');
        break;
      case _LuciqNetMenu.sendBugReport:
        await BugReporting.show(
          ReportType.bug,
          [InvocationOption.emailFieldOptional],
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google (full-screen)'),
        actions: [
          PopupMenuButton<_LuciqNetMenu>(
            tooltip: 'Luciq network toggles',
            onSelected: _onMenuSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _LuciqNetMenu.autoMaskOn,
                child: Text('Auto-masking ON (native)'),
              ),
              PopupMenuItem(
                value: _LuciqNetMenu.autoMaskOff,
                child: Text('Auto-masking OFF (native)'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _LuciqNetMenu.bodyLogOn,
                child: Text('Body logging ON (native)'),
              ),
              PopupMenuItem(
                value: _LuciqNetMenu.bodyLogOff,
                child: Text('Body logging OFF (native)'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _LuciqNetMenu.obfuscateDart,
                child: Text('Set Dart obfuscate cb (Dart HTTP only)'),
              ),
              PopupMenuItem(
                value: _LuciqNetMenu.omitDart,
                child: Text('Set Dart omit cb (Dart HTTP only)'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _LuciqNetMenu.sendBugReport,
                child: Text('Send Bug Report'),
              ),
            ],
          ),
        ],
      ),
      body: const WebView(
        key: const ValueKey('luciq_webview_google_fullscreen'),
        initialUrl: 'https://www.google.com',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}

enum _LuciqNetMenu {
  autoMaskOn,
  autoMaskOff,
  bodyLogOn,
  bodyLogOff,
  obfuscateDart,
  omitDart,
  sendBugReport,
}
