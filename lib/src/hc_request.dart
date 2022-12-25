import 'dart:async';

import 'package:http/http.dart' as http;

///this object is not a part of public api
class HcRequest {
  final http.Client client;
  HcRequest(this.client);

  Future<http.Response> get(
    String url,
    Duration? timeoutRequest,
    FutureOr<http.Response> Function()? onTimeout,
    Map<String, String>? headers,
  ) async {
    if (timeoutRequest == null) {
      return await client.get(
        Uri.parse(url),
        headers: headers,
      );
    }
    return await client
        .get(
          Uri.parse(url),
          headers: headers,
        )
        .timeout(timeoutRequest, onTimeout: onTimeout);
  }
}
