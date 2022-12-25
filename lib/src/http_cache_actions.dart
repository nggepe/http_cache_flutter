///this object used to group all actions in `HttpCache` widget
class HttpCacheActions {
  ///this object used to group all actions in `HttpCache` widget
  const HttpCacheActions({
    required this.changeUrl,
    required this.fetchWithLoading,
    required this.fetch,
    required this.refetchUrl,
    required this.refetchUrlWithLoading,
  });

  ///handle change url, this method will find the cached data first
  final void Function(String url) changeUrl;

  ///fetching with loading attribute
  final Future<void> Function() fetchWithLoading;

  ///fetch http without show loading
  final Future<void> Function() fetch;

  ///refetch the data from url
  final void Function(String url, {Map<String, String>? headers}) refetchUrl;

  ///refetch the data from url with loading state
  final void Function(String url, {Map<String, String>? headers})
      refetchUrlWithLoading;
}
