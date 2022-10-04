import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_cache_flutter/src/error_impl.dart';
import 'package:http_cache_flutter/src/http_cache_builder_data.dart';
import 'package:http_cache_flutter/src/http_cache_chiper.dart';
import 'package:http_cache_flutter/src/http_cache_storage.dart';

import 'package:http/http.dart' as http;

class HttpCache extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final Function(Object error)? onError;
  final int staleTime;

  final Widget Function(BuildContext context, HttpCacheBuilderData data)
      builder;

  const HttpCache({
    Key? key,
    required this.url,
    this.headers,
    this.onError,
    required this.builder,
    this.staleTime = 5000 * 60,
  }) : super(key: key);

  @override
  State<HttpCache> createState() => _HttpCacheState();

  static Future<HttpCacheStorage> init(
      {required Directory storageDirectory, HttpCacheChiper? chiper}) async {
    HttpCacheStorage storage = await HttpCacheStorage.initialize(
        storageDirectory: storageDirectory, chiper: chiper);
    HttpCache.storage = storage;
    return storage;
  }

  static HttpCacheStorage? _storage;

  static set storage(HttpCacheStorage storage) => _storage = storage;

  static HttpCacheStorage get storage {
    if (_storage == null) throw NoStorage();
    return _storage!;
  }
}

class _HttpCacheState extends State<HttpCache> {
  bool isLoading = false;
  HttpResponse? response;

  String url = '';
  Map<String, String>? headers;

  bool isError = false;
  Object? error;

  Timer? _periodicStale;

  @override
  void initState() {
    headers = widget.headers;
    url = widget.url;
    _periodicStale = Timer.periodic(
        Duration(milliseconds: widget.staleTime), (timer) async {});
    super.initState();
  }

  void initialize() async {
    var data = HttpCache.storage.read(url);
    if (data == null) {
      await _fetchWithLoading();
      return;
    }

    response = HttpResponse.fromMap(data);
    if (response!.expiredAt <= DateTime.now().millisecondsSinceEpoch) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      http.Response response = await http.get(
        Uri.parse(url),
        headers: widget.headers,
      );
      await HttpCache.storage.write(
          url,
          HttpResponse(
            body: response.body,
            statusCode: response.statusCode,
            bodyBytes: response.bodyBytes,
            headers: response.headers,
            expiredAt: DateTime.now().millisecondsSinceEpoch + widget.staleTime,
          ).toMap());
      _setLoading(false);
    } catch (e) {
      if (widget.onError != null) widget.onError!(e);
      error = e;
      isError = false;
      _setLoading(false);
    }
  }

  Future<void> _fetchWithLoading() async {
    _setLoading(true);
    await _fetch();
  }

  void _setLoading(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }

  @override
  void dispose() {
    _periodicStale?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HttpCache oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      HttpCacheBuilderData(
        response: response,
        isLoading: isLoading,
        isError: isError,
        error: error,
        fetch: _fetch,
        fetchWithLoading: _fetchWithLoading,
      ),
    );
  }
}
