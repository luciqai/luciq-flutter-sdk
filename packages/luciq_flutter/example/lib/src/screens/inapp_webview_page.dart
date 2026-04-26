// inapp_webview_page.dart
// Full-screen flutter_inappwebview loading google.com. Used to verify
// whether Luciq's iOS/Android WebView tracking (interactions, network
// logs, navigation repro-step screenshots) works against the
// `flutter_inappwebview` plugin the same way it does against
// `webview_flutter`. Both use WKWebView (iOS) / android.webkit.WebView
// (Android) under the hood, but they set up the navigation delegate
// differently, so Luciq's swizzle may reach one and not the other.
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:luciq_flutter/luciq_flutter.dart';

class InAppWebViewPage extends StatefulWidget {
  static const screenName = '/inapp-webview';

  const InAppWebViewPage({Key? key}) : super(key: key);

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  InAppWebViewController? _controller;
  String _currentUrl = 'https://www.google.com';

  /// Controls whether [InAppWebView] is wrapped in a [LuciqPrivateView].
  ///
  /// Why LuciqPrivateView and not Luciq.setAutoMaskScreenshotTypes(
  /// [AutoMasking.webViews])? With `useHybridComposition: false` (virtual
  /// display mode), the WebView is rendered as a texture inside Flutter's
  /// SurfaceView — there is no real Android `WebView` in the view tree for
  /// the native SDK's bytecode-instrumentation-based WebView masking to
  /// find. LuciqPrivateView works at the Flutter level: it reports the
  /// widget's rect to the native side, which then overlays a mask at that
  /// rect over the captured SurfaceView bitmap.
  bool _privateMaskEnabled = true;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final webView = InAppWebView(
      key: const ValueKey('luciq_inapp_webview_google'),
      initialUrlRequest: URLRequest(
        url: WebUri('https://www.google.com'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: false,
        // Android: put the WebView in the real Android view hierarchy
        // instead of rendering to an offscreen virtual display. Without
        // this, Luciq's screenshot pipeline walks the view tree and
        // finds a SurfaceView placeholder where the WebView should be —
        // the captured repro-step screenshot comes out white. Hybrid
        // composition costs a bit of performance but is required for
        // any screenshot/masking integration to see WebView pixels.
        useHybridComposition: false,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, url) {
        if (url != null && mounted) {
          setState(() => _currentUrl = url.toString());
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('InAppWebView (Google)'),
        actions: [
          IconButton(
            tooltip: _privateMaskEnabled
                ? 'Masking ON (tap to unmask)'
                : 'Masking OFF (tap to mask)',
            icon: Icon(
              _privateMaskEnabled ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() => _privateMaskEnabled = !_privateMaskEnabled);
              _showSnack(
                'InAppWebView masking '
                '${_privateMaskEnabled ? "enabled" : "disabled"}',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              _currentUrl,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: _privateMaskEnabled ? LuciqPrivateView(child: webView) : webView,
      floatingActionButton: FloatingActionButton(
        onPressed: () => BugReporting.show(
          ReportType.bug,
          [InvocationOption.emailFieldOptional],
        ),
        tooltip: 'Send Bug Report',
        child: const Icon(Icons.bug_report),
      ),
    );
  }
}
