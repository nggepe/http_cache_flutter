import 'package:http_cache_flutter/src/http_cache_paged/http_cache_paged_actions.dart';
import 'package:http_cache_flutter/src/http_cache_paged/http_responses.dart';

class HttpCachePagedBuilderData<T> {
  HttpCachePagedBuilderData(
      {required this.responses,
      required this.isLoading,
      required this.isError,
      required this.error,
      required this.actions,
      required this.isLoadingMoreData});

  final List<HttpResponsePagedItem> responses;

  final bool isLoading;

  final bool isError;

  final Object? error;

  final bool isLoadingMoreData;

  final HttpCachePagedActions actions;
}
