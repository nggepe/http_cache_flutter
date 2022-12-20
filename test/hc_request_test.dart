import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'hc_request_test.mocks.dart';
import 'package:http/http.dart' as http;

@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {
  group("hc request test", () {
    test("request test", () async {
      final client = MockClient();
      const String url = "https://example.com";
      var output = [
        {"nodeId": "1", "name": "hc", "fullName": "http cache"}
      ];
      when(
        client.get(Uri.parse(url)),
      ).thenAnswer((_) async {
        return http.Response(json.encode(output), 200);
      });

      final http.Response response = await client.get(Uri.parse(url));
      expect(response.body, json.encode(output));
    });
  });
}
