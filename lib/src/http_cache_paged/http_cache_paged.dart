import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_cache_flutter/http_cache_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_cache_flutter/src/error_impl.dart';
import 'package:http_cache_flutter/src/hc_log.dart';
import 'package:http_cache_flutter/src/hc_request.dart';
import 'package:http_cache_flutter/src/http_cache_chiper.dart';
import 'package:http_cache_flutter/src/http_response.dart';

class HttpCachePaged<T> extends StatefulWidget {
  final String storageKey;

  ///the initial url
  final String url;

  ///your initial header to make this package fetching data from http
  final Map<String, String>? headers;

  ///your initial header to make this package fetching data from http
  final Future<Map<String, String>>? futureHeaders;

  ///you can return your layout with this attribute.
  final Widget Function(BuildContext context, HttpCachePagedBuilderData<T> data)
      builder;

  ///stale time of the fetching, it will automatically refetch when the key already stale
  final Duration staleTime;

  ///you can debugging with this attribute
  final HttpLog log;

  ///you can use it to handle http request
  final Future<http.Response> Function(
      String url, Map<String, String>? headers)? handleRequest;

  ///this attribute used for unit test, you can mock the `http.Client` with `mockito` package
  @visibleForTesting
  final http.Client? clientSpy;

  const HttpCachePaged({
    Key? key,
    required this.storageKey,
    required this.url,
    this.headers,
    this.futureHeaders,
    required this.builder,
    this.staleTime = const Duration(minutes: 5),
    this.log = const HttpLog(),
    this.handleRequest,
    this.clientSpy,
  }) : super(key: key);

  @override
  State<HttpCachePaged<T>> createState() => _HttpCachePagedState<T>();

  static Future<HttpCacheStorage> init(
      {required Directory storageDirectory, HttpCacheChiper? chiper}) async {
    HttpCacheStorage storage = await HttpCacheStorage.initialize(
        storageDirectory: storageDirectory,
        boxName: "http_cache_storage",
        chiper: chiper);

    HttpCachePaged.storage = storage;

    return storage;
  }

  static HttpCacheStorage? _storage;

  ///initialize the storage
  static set storage(HttpCacheStorage storage) => _storage = storage;

  ///get the storage instance
  static HttpCacheStorage get storage {
    if (_storage == null) throw NoStorage();
    return _storage!;
  }
}

class _HttpCachePagedState<T> extends State<HttpCachePaged<T>> {
  late String _url;
  Map<String, String>? _headers;
  bool _isLoading = false;
  bool _isLoadingMoreData = false;
  late HttpResponsePaged pagedKey;

  List<HttpResponsePagedItem> _data = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    _url = widget.url;
    _headers = widget.futureHeaders != null
        ? await widget.futureHeaders
        : widget.headers;

    _initKey();

    if (_data.isEmpty) {
      await _fetchWithLoading();
      return;
    }

    if (_data.isEmpty || pagedKey.staleAt <= currentTime) {
      await _fetchWithLoading();
      return;
    }
    setState(() {});
  }

  int get currentTime => DateTime.now().millisecondsSinceEpoch;

  int get _nextStale => currentTime + widget.staleTime.inMilliseconds;

  void _initKey() {
    final data = HttpCachePaged.storage.read(widget.storageKey);
    if (data == null) {
      pagedKey = HttpResponsePaged(
          staleAt: currentTime + widget.staleTime.inMilliseconds,
          key: widget.storageKey,
          items: []);
      return;
    }

    pagedKey = HttpResponsePaged.fromMap(data);
    _data = pagedKey.items;
  }

  void _setLoading(bool loading) => setState(() {
        _isLoading = loading;
      });

  void _setLoadingMore(bool loading) => setState(() {
        _isLoadingMoreData = loading;
      });

  Future<void> _fetchWithLoading(
      {String? url, Map<String, String>? headers}) async {
    _setLoading(true);
    await _fetch(url: url, headers: headers);
  }

  Future<void> _fetch({String? url, Map<String, String>? headers}) async {
    if (url != null) {
      _url = url;
    }
    if (headers != null) {
      _headers = headers;
    }

    http.Response response = await _handleRequest();

    pagedKey = HttpResponsePaged(
      staleAt: _nextStale,
      key: widget.storageKey,
      items: [
        HttpResponsePagedItem(
            body: response.body,
            statusCode: response.statusCode,
            url: _url,
            bodyBytes: response.bodyBytes,
            headers: response.headers)
      ],
    );

    _data = pagedKey.items;

    await HttpCachePaged.storage.write(widget.storageKey, pagedKey.toMap());

    _setLoading(false);
  }

  Future<http.Response> _handleRequest(
      {String? url, Map<String, String>? headers}) async {
    late http.Response response;
    if (widget.handleRequest != null) {
      response = await widget.handleRequest!(url ?? _url, headers ?? _headers);
    } else {
      response = await HcRequest(
              widget.clientSpy != null ? widget.clientSpy! : http.Client())
          .get(url ?? _url, null, null, headers ?? _headers);
    }

    HCLog.handleLog(
      type: HCLogType.server,
      log: widget.log,
      response: HttpResponse(
        body: response.body,
        statusCode: response.statusCode,
        expiredAt: 0,
        staleAt: 0,
      ),
    );

    return response;
  }

  Future<void> _addMoreData(String url, {Map<String, String>? headers}) async {
    _setLoadingMore(true);
    http.Response response = await _handleRequest(url: url, headers: headers);
    _data.add(HttpResponsePagedItem(
      body: response.body,
      statusCode: response.statusCode,
      url: url,
      bodyBytes: response.bodyBytes,
      headers: response.headers,
    ));
    await HttpCachePaged.storage
        .write(widget.storageKey, pagedKey.copyWith(items: _data).toMap());
    _setLoadingMore(false);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      HttpCachePagedBuilderData<T>(
        responses: _data,
        isLoading: _isLoading,
        isLoadingMoreData: _isLoadingMoreData,
        isError: false,
        error: null,
        actions: HttpCachePagedActions(
            fetch: _fetch,
            fetchWithLoading: _fetchWithLoading,
            addMoreData: _addMoreData),
      ),
    );
  }
}
