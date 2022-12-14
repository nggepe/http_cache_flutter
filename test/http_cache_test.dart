import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpCacheStorage extends Mock implements HttpCacheStorage {
  @override
  Future<void> write(String key, value) async {}
}

class MockClient extends Mock implements http.Client {}

class MockHttpClient2 extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    if (url.path != "/refresh-token" && headers?["jwt"] == "abc123") {
      return http.Response("unauthorized", 401);
    }

    if (url.path == "/refresh-token") {
      return http.Response(json.encode({"jwt": "h29a123"}), 200);
    }

    return http.Response(
        json.encode([
          {"nodeId": "1", "name": "hc", "fullName": "http cache"}
        ]),
        200);
  }
}

class MockClient3 extends Mock implements http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    await Future.delayed(const Duration(seconds: 3));
    return http.Response(
        json.encode([
          {"nodeId": "1", "name": "hc", "fullName": "http cache"}
        ]),
        200);
  }
}

void main() {
  const String url = "https://example.com";
  var grOutput = [
    {"nodeId": "1", "name": "hc", "fullName": "http cache"}
  ];
  final HttpCacheStorage storage = MockHttpCacheStorage();

  group("e2e http cache", () {
    setUpAll(() async {
      HttpCache.storage = storage;
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDownAll(() async {
      try {
        await HttpCache.storage.clear();
      } catch (_) {}
    });

    testWidgets("render test from fetch", (tester) async {
      final client = MockClient();

      when(
        () => client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(grOutput), 200);
      });
      when(() => storage.read(url)).thenAnswer((realInvocation) => null);

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

    testWidgets("render test from fetch with request handler", (tester) async {
      final client = MockClient();

      when(
        () => client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(grOutput), 200);
      });
      when(() => storage.read(url)).thenAnswer((realInvocation) => null);

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          handleRequest: (url, headers) async {
            return http.Response(json.encode(grOutput), 200);
          },
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

    testWidgets("render test from local", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch + 30000,
            "expiredAt": DateTime.now().millisecondsSinceEpoch + 31000,
            "headers": {"Content-Type": "applications/json"},
            "statusCode": 200,
            "body": json.encode(grOutput)
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

    testWidgets("render test from local + server with timer test",
        (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch + 30000,
            "expiredAt": DateTime.now().millisecondsSinceEpoch + 31000,
            "headers": {"Content-Type": "applications/json"},
            "statusCode": 200,
            "body": json.encode(grOutput)
          });

      when(() => storage.delete(url)).thenAnswer((invocation) async {});

      when(
        () => client.get(Uri.parse(url)),
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

      await tester.pump(const Duration(milliseconds: 31000 * 2));
    });

    testWidgets("render test from local and staled data", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch - 1,
            "expiredAt": DateTime.now().millisecondsSinceEpoch + 31000,
            "headers": {"Content-Type": "applications/json"},
            "statusCode": 200,
            "body": json.encode(grOutput)
          });

      when(() => storage.delete(url)).thenAnswer((invocation) async {});

      when(
        () => client.get(Uri.parse(url)),
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

      await tester.pump(const Duration(milliseconds: 31000 * 2));
    });

    testWidgets("render test from local and expired cache", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch + 3000,
            "expiredAt": DateTime.now().millisecondsSinceEpoch - 1,
            "headers": {"Content-Type": "applications/json"},
            "statusCode": 200,
            "body": json.encode(grOutput)
          });

      when(() => storage.delete(url)).thenAnswer((invocation) async {});

      when(
        () => client.get(Uri.parse(url)),
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

      await tester.pump(const Duration(minutes: 10));
    });

    testWidgets("render test from local and hit timer", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch + 3000,
            "expiredAt": DateTime.now().millisecondsSinceEpoch - 1,
            "headers": {"Content-Type": "applications/json"},
            "statusCode": 200,
            "body": json.encode(grOutput)
          });

      when(() => storage.delete(url)).thenAnswer((invocation) async {});

      when(
        () => client.get(Uri.parse(url)),
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

      await tester.pump(const Duration(milliseconds: 3000 * 2));
    });

    testWidgets("Hit Log from from fetch with timeout", (tester) async {
      final client = MockClient();

      when(
        () => client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(grOutput), 200);
      });
      when(() => storage.read(url)).thenAnswer((realInvocation) => null);

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          log: const HttpLog(
            showLog: true,
          ),
          timeoutRequest: const Duration(milliseconds: 3000),
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

    testWidgets("Hit complete Log from from fetch", (tester) async {
      final client = MockClient();

      when(
        () => client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(grOutput), 200);
      });
      when(() => storage.read(url)).thenAnswer((realInvocation) => null);

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          log: const HttpLog(
            showLog: true,
            completeLog: true,
          ),
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

    testWidgets("Hit Log from local", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch + 30000,
            "expiredAt": DateTime.now().millisecondsSinceEpoch + 31000,
            "headers": {"Content-Type": "applications/json"},
            "statusCode": 200,
            "body": json.encode(grOutput)
          });

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          log: const HttpLog(showLog: true),
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

    testWidgets("Hit Complete Log from local", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch + 30000,
            "expiredAt": DateTime.now().millisecondsSinceEpoch + 31000,
            "headers": {"Content-Type": "applications/json"},
            "statusCode": 200,
            "body": json.encode(grOutput)
          });

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          log: const HttpLog(showLog: true, completeLog: true),
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

    testWidgets("Hit Incomplete Log Long Character from local", (tester) async {
      final client = MockClient();
      const String url = "https://example.com";

      when(() => storage.read(url)).thenAnswer((realInvocation) => {
            "staleAt": DateTime.now().millisecondsSinceEpoch + 30000,
            "expiredAt": DateTime.now().millisecondsSinceEpoch + 31000,
            "headers": {
              "Content-Type": "applications/json",
              "jwt":
                  """Bearer eyJhbGciOiJSUzI1NiJ9.eyJ1cm46ZXhhbXBsZTpjbGFpbSI6dHJ1ZSwic3ViIjoiMSIsImlhdCI6MTY3MTY3NTMwNCwiaXNzIjoidXJuOmV4YW1wbGU6aXNzdWVyIiwiYXVkIjoidXJuOmV4YW1wbGU6YXVkaWVuY2UiLCJleHAiOjE2NzE2ODI1MDR9.XYQB7vOtM-KWROvvd12kRm11sjtIJYQYjN7u9gNhNdnzGi7fVQyEnRiEUSv0xyU79khwX3QmiUvjvlSE7wT8i2MUxdVBXxAdmp51Rs3Wd0-mZzCGAbOmnd-VHhmm7HRvN9ky9F_bA85aXZVxJCLWIRGBW8ds_-kdYcaQICsa1pktthz9N4627nDzawVSCafU6NVveIKD65VR6rFHPdXIU7aW_nc2VHF2e0tdZUAXObTUH_nQj66fB_7lVAvdeuO3bTaFCLTZCnqoHo0IUjUbQXonWoP9ywBKPAU_xrDXSVmiywLmq4nypVEnkjhF5wApgjkko3azTsMDI_pNeW2Mtg"""
            },
            "statusCode": 200,
            "body": json.encode([...grOutput, ...grOutput, ...grOutput])
          });

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          log: const HttpLog(showLog: true, completeLog: true),
          refactorBody: (body) {
            var items = json.decode(body) as List?;
            expect(items, [...grOutput, ...grOutput, ...grOutput]);
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

    testWidgets("Hit afterFetch url when response 401", (tester) async {
      final client = MockHttpClient2();

      when(() => storage.read(url)).thenAnswer((realInvocation) => null);

      await tester.pumpWidget(HttpCache<List<GithubRepository>>(
          clientSpy: client,
          url: url,
          headers: const {"jwt": "abc123"},
          onAfterFetch: (response, actions) async {
            if (response.statusCode == 401) {
              actions.fetch(
                  url: url + "/refresh-token", headers: {"jwt": "abc123"});
              return false;
            }

            final body = json.decode(response.body);

            if (body is Map && body["jwt"] != null) {
              expect(body["jwt"], "h29a123");
              actions.fetch(url: url, headers: {"jwt": body["jwt"]});
              return false;
            }
            expect(body, grOutput);
            return true;
          },
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

    testWidgets("Hit change url with future headers", (tester) async {
      final client = MockHttpClient2();
      when(() => storage.read(url)).thenAnswer((realInvocation) => null);
      await tester.pumpWidget(MaterialApp(
        home: HttpCache<dynamic>(
          url: url,
          futureHeaders: headers(),
          clientSpy: client,
          builder: (context, data) {
            return TextButton(
                onPressed: () {
                  data.actions.changeUrl("https://gepcode.com", headers: {});
                },
                child: const Text("change"));
          },
        ),
      ));

      tester.tap(find.byType(TextButton));
    });

    testWidgets("Hit fetch with button", (tester) async {
      final client = MockHttpClient2();
      when(() => storage.read(url)).thenAnswer((realInvocation) => null);
      await tester.pumpWidget(MaterialApp(
        home: HttpCache<dynamic>(
          url: url,
          headers: const {},
          clientSpy: client,
          builder: (context, data) {
            return TextButton(
                onPressed: () {
                  data.actions.fetch(url: "https://gepcode.com", headers: {});
                },
                child: const Text("fetch"));
          },
        ),
      ));

      tester.tap(find.byType(TextButton));
    });
  });
}

Future<Map<String, String>> headers() async {
  return {};
}

class GithubRepository {
  final String nodeId;
  final String name;
  final String fullName;

  const GithubRepository(
      {required this.nodeId, required this.name, required this.fullName});

  factory GithubRepository.fromMap(Map<String, dynamic> map) {
    return GithubRepository(
      nodeId: map['nodeId'],
      name: map['name'],
      fullName: map['fullName'],
    );
  }
}
