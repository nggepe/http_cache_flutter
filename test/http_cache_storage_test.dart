import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:http_cache_flutter/src/http_response.dart' as hcr;
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

    test("write read and clear", () async {
      storage = await HttpCache.init(
        storageDirectory: storageDirectory,
      );
      await storage
          .write("https://example.com", {"statusCode": 200, "body": "success"});
      final data = storage.read("https://example.com");
      expect(data, {"statusCode": 200, "body": "success"});

      await storage.clear();

      final data2 = storage.read("https://example.com");
      expect(data2, null);
    });

    test("invalidate key from status", () async {
      storage = await HttpCache.init(
        storageDirectory: storageDirectory,
      );
      hcr.HttpResponse response1 = hcr.HttpResponse(
          body: "1",
          expiredAt: DateTime.now().millisecondsSinceEpoch + 3000,
          staleAt: DateTime.now().millisecondsSinceEpoch + 3000,
          statusCode: 200,
          headers: {});

      hcr.HttpResponse response2 = hcr.HttpResponse(
          body: "2",
          expiredAt: DateTime.now().millisecondsSinceEpoch + 3000,
          staleAt: DateTime.now().millisecondsSinceEpoch + 3000,
          statusCode: 200,
          headers: {});

      await storage.write("response1", response1.toMap());
      await storage.write("response2", response2.toMap());

      final response1Read = storage.read("response1");
      expect(response1Read, response1.toMap());
      final response2Read = storage.read("response2");
      expect(response2Read, response2.toMap());

      await storage.invalidate("response");

      expect(storage.read("response1"), null);
      expect(storage.read("response2"), null);
    });
  });
}
