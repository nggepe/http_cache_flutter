class NoStorage implements Exception {
  NoStorage();

  @override
  String toString() {
    return "Storage not found.\n"
        "Dont forget to initialize HttpCache package with `HttpCache.init()`";
  }
}

class OffsetStaleTime implements Exception {
  OffsetStaleTime();

  @override
  String toString() {
    return "Stale time cannot be bigger than cache time.\n"
        "Because, when the data reach the cache time, the data will delete automatically";
  }
}

void assertionHttpCache(Duration staleTime, Duration cacheTime) {
  if (staleTime.inMilliseconds > cacheTime.inMilliseconds) {
    throw OffsetStaleTime();
  }
}
