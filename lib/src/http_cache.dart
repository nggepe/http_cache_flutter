import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_cache_flutter/src/debug_configuration.dart';
import 'package:http_cache_flutter/src/error_impl.dart';
import 'package:http_cache_flutter/src/hc_log.dart';
import 'package:http_cache_flutter/src/http_cache_builder_data.dart';
import 'package:http_cache_flutter/src/http_cache_chiper.dart';
import 'package:http_cache_flutter/src/http_cache_storage.dart';

import 'package:http/http.dart' as http;
import 'package:http_cache_flutter/src/hc_request.dart';

///You can use this Object to setup the initial storage, and this object constructor to manage your http request, and caching data into the app local storage
class HttpCache<T> extends StatefulWidget {
  ///your backend url to fetch data
  final String url;

  ///your header request, this data provided by http package.
  final Map<String, String>? headers;

  final Future<Map<String, String>>? futureHeaders;

  ///this callback will run when the fetch got an error.
  final void Function(Object error)? onError;

  ///stale time of the fetching, it will automatically refetch when the key already stale
  final Duration staleTime;

  ///cache time
  final Duration cacheTime;

  ///you can debugging with this attribute
  final HttpLog log;

  ///this attribute used to refactor the response body
  final T Function(String body)? refactorBody;

  ///this attribute will be executed when the http fetch has done, and before widget get rendering.
  ///
  ///if you are return `true`, this widget will continue rendering the builder, if you are return `false` this widget will not continue rendering the builder.
  ///
  ///So, if you are return `false` and doesn't change the url, or run `fetch` or `fetchWithLoading`,
  ///this widget still periodically refetch the last url when the data on stale time or expired in cache time.
  final bool Function(http.Response response)? afterFetch;

  ///you can return your layout with this attribute.
  final Widget Function(BuildContext context, HttpCacheBuilderData<T> data)
      builder;

  ///handle timeout future
  final Duration timeoutRequest;

  ///this attribute used for unit test, you can mock the `http.Client` with `mockito` package
  @visibleForTesting
  final http.Client? clientSpy;

  ///You can use this Object to setup the initial storage, and this object constructor to manage your http request, and caching data into the app local storage
  const HttpCache({
    Key? key,
    required this.url,
    this.headers,
    this.futureHeaders,
    this.onError,
    required this.builder,
    this.staleTime = const Duration(minutes: 5),
    this.cacheTime = const Duration(minutes: 10),
    this.log = const HttpLog(),
    this.refactorBody,
    this.afterFetch,
    this.timeoutRequest = const Duration(seconds: 30),
    this.clientSpy,
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
    assertionHttpCache(widget.staleTime, widget.cacheTime);

    var data = HttpCache.storage.read(url);

    if (data == null) {
      await _fetchWithLoading();
      return;
    }

    response = HttpResponse.fromMap(data);
    setState(() {});

    HCLog.handleLog(type: HCLogType.local, response: response, log: widget.log);

    if (response!.staleAt <= DateTime.now().millisecondsSinceEpoch) {
      _fetch();
      _setPeriodicStale();
      return;
    }

    _timeoutStale = Timer(
      Duration(
          milliseconds:
              response!.staleAt - DateTime.now().millisecondsSinceEpoch),
      _setPeriodicStale,
    );
  }

  void _changeUrl(String url) {
    this.url = url;
    initialize();
  }

  void _setPeriodicStale() {
    _periodicStale = Timer.periodic(
      widget.staleTime,
      (Timer timer) {
        _fetch();
      },
    );
  }

  Future<void> _fetch() async {
    try {
      http.Response response = await HcRequest(
              widget.clientSpy != null ? widget.clientSpy! : http.Client())
          .get(
              url, widget.timeoutRequest, widget.headers, widget.futureHeaders);

      this.response = HttpResponse(
          body: response.body,
          statusCode: response.statusCode,
          bodyBytes: response.bodyBytes,
          headers: response.headers,
          expiredAt: DateTime.now().millisecondsSinceEpoch +
              widget.cacheTime.inMilliseconds,
          staleAt: DateTime.now().millisecondsSinceEpoch +
              widget.staleTime.inMilliseconds);
      await HttpCache.storage.write(url, this.response!.toMap());

      HCLog.handleLog(
        type: HCLogType.server,
        response: this.response,
        log: widget.log,
      );

      if (_isContinueRendering(response)) _setLoading(false);
    } catch (e) {
      if (widget.onError != null) widget.onError!(e);
      error = e;
      isError = false;
      _setLoading(false);
    }
  }

  bool _isContinueRendering(http.Response response) =>
      widget.afterFetch != null ? widget.afterFetch!(response) : true;

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
    T? refactorBody;
    if (response != null && widget.refactorBody != null) {
      refactorBody = widget.refactorBody!(response!.body);
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
        refactoredBody: refactorBody,
        changeUrl: _changeUrl,
      ),
    );
  }
}
