import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:http_cache_flutter/src/error_impl.dart';

void main() {
  test("http cache assertion", () {
    expect(() {
      assertionHttpCache(
          const Duration(seconds: 2), const Duration(seconds: 1));
    }, throwsA(isA<OffsetStaleTime>()));
  });

  test("http cache no storage", () {
    expect(() {
      HttpCache.storage.read("no key");
    }, throwsA(isA<NoStorage>()));
  });
}
