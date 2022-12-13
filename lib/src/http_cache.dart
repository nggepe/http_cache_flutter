import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_cache_flutter/src/debug_configuration.dart';
import 'package:http_cache_flutter/src/error_impl.dart';
import 'package:http_cache_flutter/src/hc_log.dart';
import 'package:http_cache_flutter/src/http_cache_builder_data.dart';
import 'package:http_cache_flutter/src/http_cache_chiper.dart';
import 'package:http_cache_flutter/src/http_cache_storage.dart';

import 'package:http/http.dart' as http;

///You can use this Object to setup the initial storage, and this object constructor to manage your http request, and caching data into the app local storage
class HttpCache<T> extends StatefulWidget {
  ///your backend url to fetch data
  final String url;

  ///your header request, this data provided by http package.
  final Map<String, String>? headers;

  final Future<Map<String, String>>? futureHeaders;

  ///this callback will run when the fetch got an error.
  final Function(Object error)? onError;

  ///stale time of the fetching, it will automatically refetch when the key already stale
  final Duration staleTime;

  ///you can debugging with this attribute
  final HttpLog log;

  ///this attribute used to refactor the response body
  final T Function(String body, dynamic decodedBody)? refactorBody;

  ///you can return your layout with this attribute.
  final Widget Function(BuildContext context, HttpCacheBuilderData<T> data)
      builder;

  ///You can use this Object to setup the initial storage, and this object constructor to manage your http request, and caching data into the app local storage
  const HttpCache({
    Key? key,
    required this.url,
    this.headers,
    this.futureHeaders,
    this.onError,
    required this.builder,
    this.staleTime = const Duration(minutes: 5),
    this.log = const HttpLog(),
    this.refactorBody,
  })  : assert((headers == null && futureHeaders != null) ||
            (headers != null && futureHeaders == null) ||
            (headers == null && futureHeaders == null)),
        super(key: key);

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

    HCLog.handleLog(
      type: HCLogType.local,
      level: widget.log.level,
      response: response,
      showLog: widget.log.showLog,
    );

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
        headers: widget.futureHeaders != null
            ? await widget.futureHeaders
            : widget.headers,
      );

      this.response = HttpResponse(
        body: response.body,
        statusCode: response.statusCode,
        bodyBytes: response.bodyBytes,
        headers: response.headers,
        expiredAt: DateTime.now().millisecondsSinceEpoch +
            widget.staleTime.inMilliseconds,
      );
      await HttpCache.storage.write(url, this.response!.toMap());

      HCLog.handleLog(
        type: HCLogType.local,
        level: widget.log.level,
        response: this.response,
        showLog: widget.log.showLog,
      );

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
        refactoredBody: refactorBody,
        changeUrl: _changeUrl,
      ),
    );
  }
}
