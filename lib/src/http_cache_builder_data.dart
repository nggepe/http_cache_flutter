import 'package:http_cache_flutter/src/http_cache_actions.dart';
import 'package:http_cache_flutter/src/http_response.dart';

class HttpCacheBuilderData<T> {
  HttpCacheBuilderData(
      {required this.response,
      required this.isLoading,
      required this.isError,
      required this.error,
      this.decodedBody,
      required this.refactoredBody,
      required this.actions});

  final HttpResponse? response;

  final bool isLoading;

  final bool isError;

  final Object? error;

  final dynamic decodedBody;

  final T? refactoredBody;

  final HttpCacheActions actions;
}
