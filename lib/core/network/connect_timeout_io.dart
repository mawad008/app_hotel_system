import 'dart:io';

/// Android / iOS / desktop: every `HttpClient()` created from now on gets
/// [timeout] as its connection timeout.
void installConnectTimeout(Duration timeout) {
  HttpOverrides.global = _ConnectTimeout(timeout);
}

class _ConnectTimeout extends HttpOverrides {
  _ConnectTimeout(this.timeout);

  final Duration timeout;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..connectionTimeout = timeout;
}
