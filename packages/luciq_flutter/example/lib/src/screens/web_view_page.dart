// web_view_page.dart
// POC screen for testing Luciq WebView support.
//
// Exercises:
//   - Luciq.setWebViewMonitoringEnabled (master switch)
//   - Luciq.setWebViewUserInteractionsTrackingEnabled (taps/scrolls/nav)
//   - Luciq.setWebViewNetworkTrackingEnabled (Fetch/XHR)
//   - Luciq.setAutoMaskScreenshotTypes([AutoMasking.webViews]) — native
//     auto-masking. In pure-native apps this alone masks the native WebView,
//     but Flutter embeds WebView as a platform view which is not always
//     reachable by the native masking traversal (depends on FlutterEngine
//     platform-view composition mode). So we also wrap the [WebViewWidget]
//     in a [LuciqPrivateView]; that feeds the widget's on-screen rect to
//     the Luciq-Flutter screenshot pipeline.
//
// Masking coverage per pipeline:
//   Both bug-report screenshots AND Session Replay / Repro-step screenshots
//   go through the Flutter private-view bridge installed by [LuciqWidget]
//   (via `setScreenshotMaskingHandler` on iOS and
//   `InternalCore._setScreenshotCaptor` on Android). Any widget wrapped in
//   [LuciqPrivateView] is masked in both pipelines on both platforms — as
//   long as the wrap is present in the tree at capture time.
//
//   The first Session Replay screenshot of this page fires on screen-appear,
//   so [_privateMaskEnabled] defaults to true. If you toggle it on after the
//   user has already seen the screen, the first screenshot will land in
//   repro-steps unmasked — `LuciqPrivateView` must wrap the widget before
//   the SR capture, not after.
//
// Expected verification (out of the box once the toggles are flipped):
//   - Network logs for Fetch/XHR made inside the page
//   - User steps in Repro Steps for taps/scrolls/navigations inside the page
//   - WebView loading time surfaced in APM
import 'package:flutter/material.dart';
import 'package:luciq_flutter/luciq_flutter.dart';
import 'package:luciq_flutter_example/src/widget/luciq_button.dart';
import 'package:luciq_flutter_example/src/widget/section_title.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  static const screenName = '/webview';

  const WebViewPage({Key? key}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  /// Controls whether the [WebViewWidget] is wrapped in a
  /// [LuciqPrivateView]. Toggled by the "Mask WebViews in Screenshots" and
  /// "Unmask WebViews in Screenshots" buttons.
  bool _privateMaskEnabled = true;

  /// Fully self-contained HTML exercising navigation, taps, scrolling
  /// and both XHR and Fetch requests so you can verify every WebView
  /// capability without any external server.
  static const _demoHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Luciq WebView POC</title>
  <style>
    body { font-family: -apple-system, Roboto, sans-serif; margin: 16px; color: #222; }
    h1 { color: #1976d2; }
    button { display: block; margin: 8px 0; padding: 12px 16px;
             font-size: 16px; border: none; border-radius: 6px;
             background: #1976d2; color: white; width: 100%; }
    .spacer { height: 800px; background: linear-gradient(#e3f2fd, #bbdefb); margin-top: 16px; border-radius: 8px; padding: 16px; }
    pre { background: #f5f5f5; padding: 8px; border-radius: 4px; overflow-x: auto; }
    a { color: #1976d2; }
  </style>
</head>
<body>
  <h1 id="title">Luciq WebView POC</h1>
  <p>Interact with this page to exercise Luciq WebView tracking.</p>

  <button id="fetch-btn" onclick="doFetch()">Trigger Fetch Request</button>
  <button id="xhr-btn" onclick="doXhr()">Trigger XHR Request</button>
  <button id="nav-btn" onclick="location.hash = '#section-' + Date.now()">
    Trigger In-Page Navigation
  </button>
  <a id="external-link" href="https://flutter.dev" target="_self">Navigate to flutter.dev</a>

  <pre id="log">Awaiting interactions...</pre>

  <div class="spacer">Scroll me to generate scroll user steps.</div>

  <script>
    function log(msg) {
      var el = document.getElementById('log');
      el.textContent = new Date().toISOString() + ' - ' + msg + '\\n' + el.textContent;
    }
    // Fetch/XHR URLs, headers and bodies intentionally include sensitive-looking
    // fields (email, bearer token, password, card number) so you can see what
    // Luciq's native network auto-masker does to the captured log on the
    // dashboard when `NetworkLogger.setNetworkAutoMaskingEnabled(true)`.
    //
    // httpbin.org is used (instead of jsonplaceholder) because it handles CORS
    // preflight correctly for POST + JSON body + custom Authorization header
    // (jsonplaceholder rejects the preflight, which makes the actual request
    // never fire and Luciq ends up with no log to capture). httpbin also
    // echoes the request back so you can verify what the WebView actually sent.
    function doFetch() {
      log('Fetch started');
      fetch('https://httpbin.org/post?email=test@example.com&token=abc123', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer super-secret-token-xyz'
        },
        body: JSON.stringify({
          email: 'jane.doe@example.com',
          password: 'hunter2',
          cardNumber: '4242 4242 4242 4242'
        })
      })
        .then(function (r) { return r.json(); })
        .then(function (j) { log('Fetch ok status=' + (j && j.url ? 200 : '?')); })
        .catch(function (e) { log('Fetch error ' + e); });
    }
    function doXhr() {
      log('XHR started');
      var x = new XMLHttpRequest();
      x.open('GET', 'https://httpbin.org/get?email=xhr@example.com&api_key=xhr-key-789');
      x.setRequestHeader('Authorization', 'Bearer xhr-token-456');
      x.onload = function () { log('XHR ' + x.status); };
      x.onerror = function () { log('XHR error'); };
      x.send();
    }
  </script>
</body>
</html>
''';

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadHtmlString(_demoHtml);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setMonitoring(bool enabled) async {
    await Luciq.setWebViewMonitoringEnabled(enabled);
    _showSnack('WebView monitoring ${enabled ? "enabled" : "disabled"}');
  }

  Future<void> _setUserInteractions(bool enabled) async {
    await Luciq.setWebViewUserInteractionsTrackingEnabled(enabled);
    _showSnack(
      'WebView user interactions tracking ${enabled ? "enabled" : "disabled"}',
    );
  }

  Future<void> _setNetworkTracking(bool enabled) async {
    await Luciq.setWebViewNetworkTrackingEnabled(enabled);
    _showSnack(
      'WebView network tracking ${enabled ? "enabled" : "disabled"}',
    );
  }

  Future<void> _maskWebViews() async {
    // Native auto-masking (covers apps using the SDK in pure native too).
    await Luciq.setAutoMaskScreenshotTypes(const [AutoMasking.webViews]);
    // Flutter-level fallback: wrap the WebViewWidget in LuciqPrivateView so
    // its rect is forwarded to the native screenshot pipeline even when the
    // platform-view composition mode hides the underlying WebView from the
    // native auto-mask traversal.
    setState(() => _privateMaskEnabled = true);
    _showSnack('WebView masked (auto-masking + private view)');
  }

  Future<void> _unmaskAll() async {
    await Luciq.setAutoMaskScreenshotTypes(const [AutoMasking.none]);
    setState(() => _privateMaskEnabled = false);
    _showSnack('WebView unmasked');
  }

  Future<void> _triggerBugReport() async {
    await BugReporting.show(
      ReportType.bug,
      [InvocationOption.emailFieldOptional],
    );
  }

  // ─── Network masking ──────────────────────────────────────────────────────
  //
  // Scope of each API w.r.t. WebView-captured traffic (Fetch/XHR inside the
  // WebView):
  //   - setNetworkAutoMaskingEnabled: applies NATIVELY → affects WebView logs.
  //   - setNetworkLogBodyEnabled: applies NATIVELY → affects WebView logs.
  //   - NetworkLogger.obfuscateLog / omitLog: Dart-side callback. ONLY fires
  //     for Dart-initiated HTTP (`package:http`, Dio). WebView Fetch/XHR is
  //     captured on the native side and never reaches these callbacks.

  Future<void> _setNetworkAutoMasking(bool enabled) async {
    await NetworkLogger.setNetworkAutoMaskingEnabled(enabled);
    _showSnack('Network auto-masking ${enabled ? "ENABLED" : "DISABLED"} '
        '(native — applies to WebView Fetch/XHR)');
  }

  Future<void> _setNetworkBodyLogging(bool enabled) async {
    await NetworkLogger.setNetworkLogBodyEnabled(enabled);
    _showSnack('Network body logging ${enabled ? "ENABLED" : "DISABLED"} '
        '(native — applies to WebView Fetch/XHR)');
  }

  void _setDartObfuscateCallback() {
    NetworkLogger.obfuscateLog((data) async {
      // Redact token/api_key/password query params in Dart-initiated calls.
      final masked = data.url.replaceAllMapped(
        RegExp(r'(token|api_key|password)=[^&]+', caseSensitive: false),
        (m) => '${m.group(1)}=[REDACTED]',
      );
      return data.copyWith(url: masked);
    });
    _showSnack('Dart obfuscate callback set '
        '(Dart HTTP only — does NOT affect WebView traffic)');
  }

  void _setDartOmitCallback() {
    NetworkLogger.omitLog((data) async {
      // Drop anything analytics-flavoured from Dart-initiated calls.
      return data.url.contains('analytics') ||
          data.url.contains('googletagmanager');
    });
    _showSnack('Dart omit-log callback set '
        '(Dart HTTP only — does NOT affect WebView traffic)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView POC')),
      body: Column(
        children: [
          Expanded(
            flex: 20,
            child: Builder(
              builder: (_) {
                final webView = WebViewWidget(
                  key: const ValueKey('luciq_webview_poc'),
                  controller: _controller,
                );
                return _privateMaskEnabled
                    ? LuciqPrivateView(child: webView)
                    : webView;
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const SectionTitle('Master switch'),
                  LuciqButton(
                    text: 'Enable WebView Monitoring',
                    symanticLabel: 'webview_monitoring_enable',
                    onPressed: () => _setMonitoring(true),
                  ),
                  LuciqButton(
                    text: 'Disable WebView Monitoring',
                    symanticLabel: 'webview_monitoring_disable',
                    onPressed: () => _setMonitoring(false),
                  ),
                  const SectionTitle('User interactions tracking'),
                  LuciqButton(
                    text: 'Enable User Interactions Tracking',
                    symanticLabel: 'webview_user_interactions_enable',
                    onPressed: () => _setUserInteractions(true),
                  ),
                  LuciqButton(
                    text: 'Disable User Interactions Tracking',
                    symanticLabel: 'webview_user_interactions_disable',
                    onPressed: () => _setUserInteractions(false),
                  ),
                  const SectionTitle('Network logs tracking'),
                  LuciqButton(
                    text: 'Enable Network Tracking',
                    symanticLabel: 'webview_network_tracking_enable',
                    onPressed: () => _setNetworkTracking(true),
                  ),
                  LuciqButton(
                    text: 'Disable Network Tracking',
                    symanticLabel: 'webview_network_tracking_disable',
                    onPressed: () => _setNetworkTracking(false),
                  ),
                  const SectionTitle('Screenshot masking'),
                  LuciqButton(
                    text: 'Mask WebViews in Screenshots',
                    symanticLabel: 'webview_mask_enable',
                    onPressed: _maskWebViews,
                  ),
                  LuciqButton(
                    text: 'Unmask WebViews in Screenshots',
                    symanticLabel: 'webview_mask_disable',
                    onPressed: _unmaskAll,
                  ),
                  const SectionTitle(
                    'Network masking — native (applies to WebView)',
                  ),
                  LuciqButton(
                    text: 'Enable Network Auto-masking',
                    symanticLabel: 'webview_net_automask_enable',
                    onPressed: () => _setNetworkAutoMasking(true),
                  ),
                  LuciqButton(
                    text: 'Disable Network Auto-masking',
                    symanticLabel: 'webview_net_automask_disable',
                    onPressed: () => _setNetworkAutoMasking(false),
                  ),
                  LuciqButton(
                    text: 'Enable Body Logging',
                    symanticLabel: 'webview_net_body_enable',
                    onPressed: () => _setNetworkBodyLogging(true),
                  ),
                  LuciqButton(
                    text: 'Disable Body Logging',
                    symanticLabel: 'webview_net_body_disable',
                    onPressed: () => _setNetworkBodyLogging(false),
                  ),
                  const SectionTitle(
                    'Network masking — Dart callbacks (Dart HTTP only)',
                  ),
                  LuciqButton(
                    text: 'Set Obfuscate Callback (redact token/api_key)',
                    symanticLabel: 'webview_net_obfuscate_set',
                    onPressed: _setDartObfuscateCallback,
                  ),
                  LuciqButton(
                    text: 'Set Omit Callback (drop analytics URLs)',
                    symanticLabel: 'webview_net_omit_set',
                    onPressed: _setDartOmitCallback,
                  ),
                  const SectionTitle('Send a report'),
                  LuciqButton(
                    text: 'Send Bug Report',
                    symanticLabel: 'webview_send_bug_report',
                    onPressed: _triggerBugReport,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
