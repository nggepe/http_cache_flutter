import 'dart:developer' as developer;
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:http_cache_flutter/src/http_response.dart';

class HCLog {
  static void handleLog({
    required HCLogType type,
    HttpResponse? response,
    required HttpLog log,
  }) {
    final String newType = type.toString().split(".").last;
    if (log.showLog) {
      developer.log(
        response?.statusCode.toString() ?? "",
        name: '$newType response Status code',
        level: log.level,
      );

      var headers = response?.headers.toString() ?? "";
      if (headers.length > 100 && !log.completeLog) {
        headers = headers.substring(0, 100);
      }
      developer.log(
        headers,
        name: '$newType response header',
        level: log.level,
      );

      var body = response?.body.toString() ?? "";
      if (body.length > 100 && !log.completeLog) {
        body = body.substring(0, 100);
      }
      developer.log(
        body,
        name: '$newType response body',
        level: log.level,
      );
    }
  }
}

enum HCLogType { local, server }
