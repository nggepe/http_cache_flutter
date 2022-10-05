import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_cache_flutter/src/debug_configuration.dart';
import 'package:http_cache_flutter/src/error_impl.dart';
import 'package:http_cache_flutter/src/http_cache_builder_data.dart';
import 'package:http_cache_flutter/src/http_cache_chiper.dart';
import 'package:http_cache_flutter/src/http_cache_storage.dart';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

class HttpCache<T> extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final Function(Object error)? onError;
  final Duration staleTime;
  final DebugProps httpLog;
  final T Function(String body, dynamic decodedBody)? refactorBody;
  final Widget Function(BuildContext context, HttpCacheBuilderData<T> data)
      builder;

  const HttpCache({
    Key? key,
    required this.url,
    this.headers,
    this.onError,
    required this.builder,
    this.staleTime = const Duration(minutes: 5),
    this.httpLog = const DebugProps(),
    this.refactorBody,
  }) : super(key: key);

  @override
  State<HttpCache> createState() => _HttpCacheState<T>();

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

class _HttpCacheState<T> extends State<HttpCache<T>> {
  bool isLoading = false;
  HttpResponse? response;

  String url = '';
  Map<String, String>? headers;

  bool isError = false;
  Object? error;

  Timer? _periodicStale;
  Timer? _timeoutStale;

  @override
  void initState() {
    headers = widget.headers;
    url = widget.url;
    initialize();
    super.initState();
  }

  void initialize() async {
    var data = HttpCache.storage.read(url);

    if (data == null) {
      await _fetchWithLoading();
      return;
    }

    response = HttpResponse.fromMap(data);
    setState(() {});

    if (response!.expiredAt <= DateTime.now().millisecondsSinceEpoch) {
      _fetch();
      _setPeriodic();
    } else {
      _timeoutStale = Timer(
        Duration(
            milliseconds:
                response!.expiredAt - DateTime.now().millisecondsSinceEpoch),
        _setPeriodic,
      );
    }
  }

  void _changeUrl(String url) {
    this.url = url;
    initialize();
  }

  _setPeriodic() {
    _periodicStale = Timer.periodic(
      widget.staleTime,
      (Timer timer) {
        _fetch();
      },
    );
  }

  Future<void> _fetch() async {
    try {
      http.Response response = await http.get(
        Uri.parse(url),
        headers: widget.headers,
      );

      if (widget.httpLog.showLog) {
        developer.log(
          response.statusCode.toString(),
          name: '[server response] Status code',
          level: widget.httpLog.level,
        );
        developer.log(
          response.headers.toString(),
          name: '[server response] header',
          level: widget.httpLog.level,
        );
        developer.log(
          response.body,
          name: '[server response] body',
          level: widget.httpLog.level,
        );
      }

      await HttpCache.storage.write(
          url,
          HttpResponse(
            body: response.body,
            statusCode: response.statusCode,
            bodyBytes: response.bodyBytes,
            headers: response.headers,
            expiredAt: DateTime.now().millisecondsSinceEpoch +
                widget.staleTime.inMilliseconds,
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
    _timeoutStale?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HttpCache<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    var decodedBody =
        response?.body != null ? json.decode(response!.body) : null;
    T? refactorBody;
    if (response != null && widget.refactorBody != null) {
      refactorBody = widget.refactorBody!(response!.body, decodedBody);
    }
    return widget.builder(
      context,
      HttpCacheBuilderData<T>(
        response: response,
        isLoading: isLoading,
        isError: isError,
        error: error,
        fetch: _fetch,
        fetchWithLoading: _fetchWithLoading,
        decodedBody: decodedBody,
        refactorBody: refactorBody,
        changeUrl: _changeUrl,
      ),
    );
  }
}
