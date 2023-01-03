import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http_cache_flutter/src/debug_configuration.dart';
import 'package:http_cache_flutter/src/error_impl.dart';
import 'package:http_cache_flutter/src/hc_log.dart';
import 'package:http_cache_flutter/src/http_cache_actions.dart';
import 'package:http_cache_flutter/src/http_cache_builder_data.dart';
import 'package:http_cache_flutter/src/http_cache_chiper.dart';
import 'package:http_cache_flutter/src/http_cache_storage.dart';

import 'package:http/http.dart' as http;
import 'package:http_cache_flutter/src/hc_request.dart';
import 'package:http_cache_flutter/src/http_response.dart';

///You can use this **Widget** to setup the initial storage, and this object constructor to manage your http request, and caching data into the app local storage
class HttpCache<T> extends StatefulWidget {
  ///your backend url to fetch data
  final String url;

  ///your header request, this data provided by http package.
  final Map<String, String>? headers;

  final Future<Map<String, String>>? futureHeaders;

  ///this callback will run when the fetch got an error.
  final Widget Function(BuildContext context, Object? error)? onError;

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
  final Future<bool> Function(http.Response response, HttpCacheActions actions)?
      onAfterFetch;

  ///you can return your layout with this attribute.
  final Widget Function(BuildContext context, HttpCacheBuilderData<T> data)
      builder;

  ///handle timeout future
  final Duration? timeoutRequest;

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
    this.cacheTime = const Duration(minutes: 6),
    this.log = const HttpLog(),
    this.refactorBody,
    this.onAfterFetch,
    this.timeoutRequest,
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

  ///initialize the storage
  static set storage(HttpCacheStorage storage) => _storage = storage;

  ///get the storage instance
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
  Timer? _periodicCache;
  Timer? _timeoutCache;

  @override
  void initState() {
    url = widget.url;
    _initialize();
    super.initState();
  }

  void _initialize() async {
    assertionHttpCache(widget.staleTime, widget.cacheTime);

    headers = widget.futureHeaders == null
        ? await widget.futureHeaders
        : widget.headers;

    var data = HttpCache.storage.read(url);

    if (data == null) {
      await _fetchWithLoading();
      return;
    }

    response = HttpResponse.fromMap(data);
    if (mounted) setState(() {});

    HCLog.handleLog(type: HCLogType.local, response: response, log: widget.log);

    _handleStale(response!);
    _handleCache(response!);
  }

  void _handleCache(HttpResponse response) async {
    if (response.expiredAt <= DateTime.now().millisecondsSinceEpoch) {
      HttpCache.storage.delete(url);
      _periodicCache = Timer.periodic(widget.cacheTime, (timer) {
        HttpCache.storage.delete(url);
      });
      return;
    }

    _timeoutCache = Timer(
        Duration(
            milliseconds: response.expiredAt -
                DateTime.now().millisecondsSinceEpoch), () async {
      await HttpCache.storage.delete(url);
      _periodicCache = Timer.periodic(widget.cacheTime, (timer) {
        HttpCache.storage.delete(url);
      });
    });
  }

  void _handleStale(HttpResponse response) async {
    if (response.staleAt <= DateTime.now().millisecondsSinceEpoch) {
      _fetch();
      _setPeriodicStale();
      return;
    }

    _timeoutStale = Timer(
        Duration(
            milliseconds:
                response.staleAt - DateTime.now().millisecondsSinceEpoch),
        _setPeriodicStale);
  }

  void _changeUrl(String url, {Map<String, String>? headers}) {
    this.url = url;
    if (headers != null) {
      this.headers = headers;
    }
    _initialize();
  }

  void _setPeriodicStale() {
    _periodicStale = Timer.periodic(
      widget.staleTime,
      (Timer timer) {
        _fetch();
      },
    );
  }

  ///fetching http request
  Future<void> _fetch({String? url, Map<String, String>? headers}) async {
    if (url != null) {
      this.url = url;
    }
    if (headers != null) {
      this.headers = headers;
    }
    try {
      http.Response response = await HcRequest(
              widget.clientSpy != null ? widget.clientSpy! : http.Client())
          .get(this.url, widget.timeoutRequest, null, this.headers);

      this.response = HttpResponse(
          body: response.body,
          statusCode: response.statusCode,
          bodyBytes: response.bodyBytes,
          headers: response.headers,
          expiredAt: DateTime.now().millisecondsSinceEpoch +
              widget.cacheTime.inMilliseconds,
          staleAt: DateTime.now().millisecondsSinceEpoch +
              widget.staleTime.inMilliseconds);
      await HttpCache.storage.write(this.url, this.response!.toMap());

      HCLog.handleLog(
        type: HCLogType.server,
        response: this.response,
        log: widget.log,
      );

      if (await _isContinueRendering(response)) _setLoading(false);
    } catch (e) {
      if (widget.onError == null) rethrow;
      error = e;
      isError = true;
      _setLoading(false);
    }
  }

  Future<bool> _isContinueRendering(http.Response response) async =>
      widget.onAfterFetch != null
          ? await widget.onAfterFetch!(
              response,
              HttpCacheActions(
                changeUrl: _changeUrl,
                fetchWithLoading: _fetchWithLoading,
                fetch: _fetch,
              ))
          : true;

  Future<void> _fetchWithLoading(
      {String? url, Map<String, String>? headers}) async {
    _setLoading(true);
    await _fetch(url: url, headers: headers);
  }

  ///set loading state
  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  @override
  void dispose() {
    _periodicStale?.cancel();
    _periodicCache?.cancel();
    _timeoutCache?.cancel();
    _timeoutStale?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isError && widget.onError != null) {
      return widget.onError!(context, error);
    }

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
        actions: HttpCacheActions(
          changeUrl: _changeUrl,
          fetchWithLoading: _fetchWithLoading,
          fetch: _fetch,
        ),
        refactoredBody: refactorBody,
      ),
    );
  }
}
