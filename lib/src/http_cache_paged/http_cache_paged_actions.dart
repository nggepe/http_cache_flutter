class HttpCachePagedActions {
  final Future<void> Function({String? url, Map<String, String>? headers})
      fetch;
  final Future<void> Function({String? url, Map<String, String>? headers})
      fetchWithLoading;

  ///handle get more data from a new http url
  final Future<void> Function(String url, {Map<String, String>? headers})
      addMoreData;

  const HttpCachePagedActions({
    required this.fetch,
    required this.fetchWithLoading,
    required this.addMoreData,
  });
}
