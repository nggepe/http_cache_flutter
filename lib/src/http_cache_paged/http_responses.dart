import 'package:flutter/foundation.dart';

class HttpResponsePaged {
  final int staleAt;
  final String key;
  final List<HttpResponsePagedItem> items;
  HttpResponsePaged({
    required this.staleAt,
    required this.key,
    required this.items,
  });

  HttpResponsePaged copyWith({
    int? staleAt,
    String? key,
    List<HttpResponsePagedItem>? items,
  }) {
    return HttpResponsePaged(
      staleAt: staleAt ?? this.staleAt,
      key: key ?? this.key,
      items: items ?? this.items,
    );
  }

  Map toMap() => {
        "staleAt": staleAt,
        "key": key,
        "items": items.map((e) => e.toMap()).toList(),
      };

  factory HttpResponsePaged.fromMap(Map map) {
    return HttpResponsePaged(
      staleAt: map['staleAt'] as int,
      key: map['key'] as String,
      items: List<HttpResponsePagedItem>.from(
        (map['items'] as List<int>).map<HttpResponsePagedItem>(
          (x) => HttpResponsePagedItem.fromMap(x as Map),
        ),
      ),
    );
  }
}

class HttpResponsePagedItem {
  final String body;
  final int statusCode;
  final Uint8List? bodyBytes;
  final Map<String, String>? headers;
  final String url;

  HttpResponsePagedItem({
    required this.body,
    required this.statusCode,
    this.bodyBytes,
    this.headers,
    required this.url,
  });

  factory HttpResponsePagedItem.fromMap(Map map) {
    return HttpResponsePagedItem(
      body: map['body'] as String,
      statusCode: map['statusCode'] as int,
      bodyBytes: map['bodyBytes'],
      headers: map['headers'],
      url: map['url'] as String,
    );
  }

  Map toMap() => {
        "body": body,
        "statusCode": statusCode,
        "bodyBytes": bodyBytes,
        "headers": headers,
        "url": url,
      };
}
