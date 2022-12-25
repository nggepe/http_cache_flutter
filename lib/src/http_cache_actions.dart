///this object used to group all actions in `HttpCache` widget
class HttpCacheActions {
  ///this object used to group all actions in `HttpCache` widget
  const HttpCacheActions({
    required this.changeUrl,
    required this.fetchWithLoading,
    required this.fetch,
  });

  ///handle change url, this method will find the cached data first
  final void Function(String url, {Map<String, String>? headers}) changeUrl;

  ///fetching with loading attribute
  final Future<void> Function({String? url, Map<String, String>? headers})
      fetchWithLoading;

  ///fetch http without show loading
  final Future<void> Function({String? url, Map<String, String>? headers})
      fetch;
}
