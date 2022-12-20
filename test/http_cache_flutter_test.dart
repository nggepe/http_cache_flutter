import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'hc_request_test.mocks.dart';
import 'http_cache_flutter_test.mocks.dart';

const String url = "https://example.com";
var grOutput = [
  {"nodeId": "1", "name": "hc", "fullName": "http cache"}
];
final HttpCacheStorage storage = MockHttpCacheStorage();

@GenerateNiceMocks([MockSpec<HttpCacheStorage>()])
void main() {
  group("e2e test", () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(() async {
      HttpCache.storage = storage;
    });

    tearDownAll(() async {
      try {
        await HttpCache.storage.clear();
      } catch (_) {}
    });

    testWidgets("render test from fetch", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(
        client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(grOutput), 200);
      });
      when(storage.read(url)).thenAnswer((realInvocation) => null);

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
