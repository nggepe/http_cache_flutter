import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache_flutter/src/http_response.dart';

void main() {
  test("http response copy with test", () {
    final HttpResponse response = HttpResponse(
        body: "body", statusCode: 100, expiredAt: 400, staleAt: 300);
    final newResponse = response.copyWith(
      body: "body1",
      expiredAt: 100,
      staleAt: 200,
      statusCode: 200,
    );

    expect(newResponse.body, "body1");
    expect(newResponse.expiredAt, 100);
    expect(newResponse.staleAt, 200);
    expect(newResponse.statusCode, 200);
  });
}
