import 'package:http_cache_flutter/src/http_response.dart';

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
