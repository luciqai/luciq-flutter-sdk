part of '../../main.dart';

class NetworkContent extends StatefulWidget {
  const NetworkContent({Key? key}) : super(key: key);
  final String defaultRequestUrl =
      'https://jsonplaceholder.typicode.com/posts/1';

  @override
  State<NetworkContent> createState() => _NetworkContentState();
}

class _NetworkContentState extends State<NetworkContent> {
  final http = LuciqHttpClient();

  final endpointUrlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LuciqClipboardInput(
          label: 'Endpoint Url',
          symanticLabel: 'endpoint_url_input',
          controller: endpointUrlController,
        ),
        LuciqButton(
          text: 'Send Request To Url',
          symanticLabel: 'make_http_request',
          onPressed: () => _sendRequestToUrl(endpointUrlController.text),
        ),
        LuciqButton(
          text: 'Send Get Request ',
          symanticLabel: 'make_get_request',
          onPressed: () => _sendGetRequestToUrl('https://httpbin.org/get'),
        ),
        LuciqButton(
          text: 'Send Post Request ',
          symanticLabel: 'make_post_request',
          onPressed: () => _sendPostRequestToUrl('https://httpbin.org/post'),
        ),
        LuciqButton(
          text: 'Send put Request ',
          symanticLabel: 'make_put_request',
          onPressed: () => _sendPutRequestToUrl('https://httpbin.org/put'),
        ),
        LuciqButton(
          text: 'Send delete Request ',
          symanticLabel: 'make_delete_request',
          onPressed: () =>
              _sendDeleteRequestToUrl('https://httpbin.org/delete'),
        ),
        LuciqButton(
          text: 'Send patch Request ',
          symanticLabel: 'make_patch_request',
          onPressed: () => _sendPatchRequestToUrl('https://httpbin.org/patch'),
        ),
        const Text("W3C Header Section"),
        LuciqButton(
          text: 'Send Request With Custom traceparent header',
          symanticLabel: 'make_http_request_with_traceparent_header',
          onPressed: () => _sendRequestToUrl(
            endpointUrlController.text,
            headers: {"traceparent": "Custom traceparent header"},
          ),
        ),
        LuciqButton(
          text: 'Send Request  Without Custom traceparent header',
          symanticLabel: 'make_http_request_with_w3c_header',
          onPressed: () => _sendRequestToUrl(endpointUrlController.text),
        ),
        LuciqButton(
          text: 'obfuscateLog',
          symanticLabel: 'obfuscate_log',
          onPressed: () {
            NetworkLogger.obfuscateLog((networkData) async {
              return networkData.copyWith(url: 'fake url');
            });
          },
        ),
        LuciqButton(
          text: 'omitLog',
          symanticLabel: 'omit_log',
          onPressed: () {
            NetworkLogger.omitLog((networkData) async {
              return networkData.url.contains('google.com');
            });
          },
        ),
        LuciqButton(
          text: 'obfuscateLogWithException',
          symanticLabel: 'obfuscate_log_with_exception',
          onPressed: () {
            NetworkLogger.obfuscateLog((networkData) async {
              throw Exception("obfuscateLogWithException");

              return networkData.copyWith(url: 'fake url');
            });
          },
        ),
        LuciqButton(
          text: 'omitLogWithException',
          symanticLabel: 'omit_log_with_exception',
          onPressed: () {
            NetworkLogger.omitLog((networkData) async {
              throw Exception("OmitLog with exception");

              return networkData.url.contains('google.com');
            });
          },
        ),
      ],
    );
  }

  Future<void> _sendRequestToUrl(String text,
      {Map<String, String>? headers}) async {
    try {
      final url = text.trim().isEmpty ? widget.defaultRequestUrl : text;
      final response = await http.get(Uri.parse(url), headers: headers);

      // Handle the response here
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log(jsonEncode(jsonData));
      } else {
        log('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending request: $e');
    }
  }

  Future<void> _sendGetRequestToUrl(String text,
      {Map<String, String>? headers}) async {
    try {
      final url = text.trim().isEmpty ? widget.defaultRequestUrl : text;
      final response = await http.get(Uri.parse(url), headers: headers);

      // Handle the response here
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log(jsonEncode(jsonData));
      } else {
        log('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending request: $e');
    }
  }

  Future<void> _sendPostRequestToUrl(
    String text, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = text.trim().isEmpty ? widget.defaultRequestUrl : text;
      final response = await http.post(Uri.parse(url), headers: headers);

      // Handle the response here
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log(jsonEncode(jsonData));
      } else {
        log('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending request: $e');
    }
  }

  Future<void> _sendPutRequestToUrl(String text,
      {Map<String, String>? headers}) async {
    try {
      final url = text.trim().isEmpty ? widget.defaultRequestUrl : text;
      final response = await http.put(Uri.parse(url), headers: headers);

      // Handle the response here
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log(jsonEncode(jsonData));
      } else {
        log('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending request: $e');
    }
  }

  Future<void> _sendDeleteRequestToUrl(
    String text, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = text.trim().isEmpty ? widget.defaultRequestUrl : text;
      final response = await http.delete(Uri.parse(url), headers: headers);

      // Handle the response here
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log(jsonEncode(jsonData));
      } else {
        log('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending request: $e');
    }
  }

  Future<void> _sendPatchRequestToUrl(
    String text, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = text.trim().isEmpty ? widget.defaultRequestUrl : text;
      final response = await http.patch(Uri.parse(url), headers: headers);

      // Handle the response here
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        log(jsonEncode(jsonData));
      } else {
        log('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending request: $e');
    }
  }
}
