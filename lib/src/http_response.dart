import 'dart:typed_data';

//it is not a part of public api
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
