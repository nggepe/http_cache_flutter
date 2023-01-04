# HttpCache Widget Class Documentation

You can use this **Widget** to setup the initial storage, and this object constructor to manage your http request, and caching data into the app local storage

## Setup storage implementation

you can use `path_provider` package on pub.dev or run `flutter pub add path_provider`.
Here is the example to setup your `main.dart` project.

```dart
import "package:path_provider/path_provider.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:http_cache_flutter/http_cache_flutter.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HttpCache.init(
      storageDirectory: kIsWeb
          ? HttpCacheStorage.webStorageDirectory
          : await getTemporaryDirectory());
  runApp(const MyApp());
}
```

## Attribute Descriptions

1. `String url`: is your initial url to make this package fetching data from http
2. `Map<String, String>? headers`: is your initial header to make this package fetching data from http
3. `Future<Map<String, String>>? futureHeaders`: is your initial header to make this package fetching data from http, you can use it when you don't initialize the `headers` attribute. the package will auto fetch using this headers
4. `Widget Function(BuildContext context, Object? error)? onError`: this callback will run when the fetch got an error.
5. `Duration staleTime`: stale time of the fetching, it will automatically refetch when the key already stale
6. `Duration cacheTime`: cache time of the data, it will automatically remove the cache when the expired
7. `HttpLog log`: you can debugging with this attribute
8. `T Function(String body)? refactorBody`: this attribute used to refactor the response body. this package will execute this method after local fetch or http fetch.
9. `Future<bool> Function(http.Response response, HttpCacheActions actions)? onAfterFetch`: this attribute will be executed when the http fetch has done, and before widget get rendering. if you are return `true`, this widget will continue rendering the builder, if you are return `false` this widget will not continue rendering the builder. So, if you are return `false` and doesn't change the url, or run `fetch` or `fetchWithLoading`, this widget still periodically refetch the last url when the data on stale time or expired in cache time.
10. `Widget Function(BuildContext context, HttpCacheBuilderData<T> data) builder`: you can return your layout with this attribute.
11. `Duration? timeoutRequest`: handle timeout future request
12. `http.Client? clientSpy`: this attribute used for unit test, you can mock the `http.Client` using `mockito` package or using `mocktail` package
13. `Future<http.Response> Function(String url, Map<String, String>? headers)? handleRequest`: you can use it to handle http request
