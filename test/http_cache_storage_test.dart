import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

class MockBox extends Mock implements Box {}

void main() {
  final cwd = Directory.current.path;
  final storageDirectory = Directory(path.join(cwd, ".cache"));
  group("http_storage test", () {
    late HttpCacheStorage storage;
    tearDown(() async {
      await storage.clear();
      try {
        await HttpCacheStorage.hive.deleteFromDisk();
      } catch (_) {}
    });
    test("read", () async {
      storage = await HttpCache.init(
        storageDirectory: storageDirectory,
      );
      await storage
          .write("https://example.com", {"statusCode": 200, "body": "success"});
      final data = storage.read("https://example.com");
      expect(data, {"statusCode": 200, "body": "success"});
    });
  });
}
