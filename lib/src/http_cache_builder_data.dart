// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

class HttpCacheBuilderData<T> {
  HttpCacheBuilderData(
      {required this.response,
      required this.isLoading,
      required this.isError,
      required this.error,
      required this.fetch,
      required this.fetchWithLoading,
      this.decodedBody,
      required this.refactoredBody,
      required this.changeUrl});

  final HttpResponse? response;

  final bool isLoading;

  final bool isError;

  final Object? error;

  final Future<void> Function() fetch;

  final Future<void> Function() fetchWithLoading;

  final dynamic decodedBody;

  final T? refactoredBody;

  final void Function(String url) changeUrl;
}

class HttpResponse {
  final String body;
  final int statusCode;
  final Uint8List? bodyBytes;
  final Map<String, String>? headers;
  final int expiredAt;
  final int staleAt;
  HttpResponse({
    required this.body,
    required this.statusCode,
    this.bodyBytes,
    this.headers,
    required this.expiredAt,
    required this.staleAt,
  });

  HttpResponse copyWith({
    String? body,
    int? statusCode,
    Uint8List? bodyBytes,
    Map<String, String>? headers,
    int? expiredAt,
    int? staleAt,
  }) {
    return HttpResponse(
        body: body ?? this.body,
        statusCode: statusCode ?? this.statusCode,
        bodyBytes: bodyBytes ?? this.bodyBytes,
        headers: headers ?? this.headers,
        expiredAt: expiredAt ?? this.expiredAt,
        staleAt: staleAt ?? this.staleAt);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'body': body,
      'statusCode': statusCode,
      'bodyBytes': bodyBytes,
      'headers': headers,
      'expiredAt': expiredAt,
      'staleAt': staleAt,
    };
  }

  factory HttpResponse.fromMap(Map map) {
    return HttpResponse(
        body: map['body'] as String,
        statusCode: map['statusCode'] as int,
        bodyBytes: map['bodyBytes'],
        headers: (map['headers'] as Map)
            .map((key, value) => MapEntry(key.toString(), value)),
        expiredAt: map['expiredAt'] ?? DateTime.now().millisecondsSinceEpoch,
        staleAt: map['staleAt'] ?? DateTime.now().millisecondsSinceEpoch);
  }
}
