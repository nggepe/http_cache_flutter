import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache_flutter/src/http_response.dart';

void main() {
  test("http response copy with test", () {
    final HttpResponse response = HttpResponse(
      body: "body",
      statusCode: 100,
      expiredAt: 400,
      staleAt: 300,
      bodyBytes: Uint8List.fromList(
        [0x40, 0x09, 0x21, 0xFB, 0x54, 0x44, 0x2D, 0x18],
      ),
      headers: {"Content-Type": "application/json", "Accepted-Language": "id"},
    );
    final newResponse = response.copyWith(
      body: "body1",
      expiredAt: 100,
      staleAt: 200,
      statusCode: 200,
      bodyBytes: Uint8List.fromList(
        [0x40, 0x09, 0x21, 0xFB, 0x54, 0x44, 0x2D, 0x11],
      ),
      headers: {"Content-Type": "application/json", "Accepted-Language": "en"},
    );

    expect(newResponse.body, "body1");
    expect(newResponse.expiredAt, 100);
    expect(newResponse.staleAt, 200);
    expect(newResponse.statusCode, 200);
    expect(
        newResponse.bodyBytes.toString(),
        Uint8List.fromList(
          [0x40, 0x09, 0x21, 0xFB, 0x54, 0x44, 0x2D, 0x11],
        ).toString());
    expect(newResponse.headers,
        {"Content-Type": "application/json", "Accepted-Language": "en"});

    //hit empty copyWith
    final response2 = response.copyWith();
    expect(response2.body, "body");
    expect(response2.expiredAt, 400);
    expect(response2.staleAt, 300);
    expect(response2.statusCode, 100);
    expect(
        response2.bodyBytes.toString(),
        Uint8List.fromList(
          [0x40, 0x09, 0x21, 0xFB, 0x54, 0x44, 0x2D, 0x18],
        ).toString());
    expect(response2.headers,
        {"Content-Type": "application/json", "Accepted-Language": "id"});
  });
}
