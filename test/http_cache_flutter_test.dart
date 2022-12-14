import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class ClientSpy extends Mock implements http.Client {}

final client = ClientSpy();

void main() {
  group("e2e test", () {
    late HttpCacheStorage storage;
    setUp(() async {
      storage = await HttpCache.init(
          storageDirectory:
              Directory(path.join(Directory.current.path, 'cache')));
    });

    test("render test", () {
      final String url = "https://github.com/repository";
      when(
        () => client.get(Uri.parse(url)),
      ).thenAnswer((invocation) async => http.Response('{}', 200));
    });
  });
}
