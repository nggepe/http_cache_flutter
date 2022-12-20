import 'package:http/http.dart' as http;

class HcRequest {
  final http.Client client;
  HcRequest(this.client);

  Future<http.Response> get(
    String url,
    Duration timeoutRequest,
    Map<String, String>? headers,
    Future<Map<String, String>>? futureHeaders,
  ) async {
    return await client
        .get(
          Uri.parse(url),
          headers: futureHeaders != null ? await futureHeaders : headers,
        )
        .timeout(timeoutRequest);
  }
}
