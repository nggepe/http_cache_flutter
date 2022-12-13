import 'dart:developer' as developer;

import 'package:http_cache_flutter/src/http_cache_builder_data.dart';

class HCLog {
  static void handleLog({
    bool showLog = false,
    required HCLogType type,
    HttpResponse? response,
    int level = 0,
  }) {
    final String newType = type.toString().split(".").last;
    if (showLog) {
      developer.log(
        response?.statusCode.toString() ?? "",
        name: '[$newType response] Status code',
        level: level,
      );
      developer.log(
        response?.headers.toString() ?? "",
        name: '[$newType response] header',
        level: level,
      );
      developer.log(
        response?.body ?? "",
        name: '[$newType response] body',
        level: level,
      );
    }
  }
}

enum HCLogType { local, server }
