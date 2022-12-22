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

  test("http cache assertion to string", () {
    try {
      assertionHttpCache(
          const Duration(seconds: 2), const Duration(seconds: 1));
    } catch (e) {
      expect(
          e.toString(),
          "Stale time cannot be bigger than cache time.\n"
          "Because, when the data reach the cache time, the data will delete automatically");
    }
  });

  test("http cache no storage", () {
    try {
      HttpCache.storage.read("no key");
    } catch (e) {
      expect(
          e.toString(),
          "Storage not found.\n"
          "Dont forget to initialize HttpCache package with `HttpCache.init()`");
    }
  });
}
