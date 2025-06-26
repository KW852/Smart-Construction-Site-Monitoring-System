import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MonitorPage extends StatelessWidget {
  final String streamUrl = 'https://xxxx';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Monitoring'),
      ),
      body: WebView(
        initialUrl: streamUrl,
        javascriptMode: JavascriptMode.unrestricted,
        userAgent: 'MyCustomUserAgent',
        onPageStarted: (url) {
          debugPrint('Page started loading: $url');
        },
        onPageFinished: (url) {
          debugPrint('Page finished loading: $url');
        },
        navigationDelegate: (NavigationRequest request) {
          debugPrint('Navigating to: ${request.url}');
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}