import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import 'hc_request_test.mocks.dart';

const String url = "https://example.com";
var grOutput = [
  {"nodeId": "1", "name": "hc", "fullName": "http cache"}
];
@GenerateNiceMocks([MockSpec<HttpCacheStorage>()])
void main() {
  group("e2e test", () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUp(() async {
      HttpCache.storage = await HttpCache.init(
          storageDirectory:
              Directory(path.join(Directory.current.path, 'cache')));
    });

    tearDown(() async {
      try {
        // Directory(
        //   path.join(Directory.current.path, 'cache'),
        // ).deleteSync(recursive: true);
        await HttpCache.storage.clear();
        // await HttpCacheStorage.hive.deleteFromDisk();
      } catch (_) {}
    });

    testWidgets("render test", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";
      when(
        client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(grOutput), 200);
      });

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          refactorBody: (body) {
            var items = json.decode(body) as List?;
            expect(items, grOutput);
            return items?.map((e) {
                  return GithubRepository.fromMap(e);
                }).toList() ??
                [];
          },
          builder: (_, data) {
            expect(data.refactoredBody, isA<List<GithubRepository>?>());
            return Container();
          }));
    });
  });
}

class GithubRepository {
  final String nodeId;
  final String name;
  final String fullName;

  const GithubRepository(
      {required this.nodeId, required this.name, required this.fullName});

  factory GithubRepository.fromMap(Map<String, dynamic> map) {
    return GithubRepository(
      nodeId: map['node_id'],
      name: map['name'],
      fullName: map['full_name'],
    );
  }
}
