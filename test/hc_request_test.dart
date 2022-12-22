import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  group("hc request test", () {
    test("request test", () async {
      final client = MockClient();
      const String url = "https://example.com";
      var output = [
        {"nodeId": "1", "name": "hc", "fullName": "http cache"}
      ];
      when(
        () => client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(output), 200);
      });

      final http.Response response = await client.get(Uri.parse(url));
      expect(response.body, json.encode(output));
    });
  });
}
