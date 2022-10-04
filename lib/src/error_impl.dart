class NoStorage implements Exception {
  NoStorage();

  @override
  String toString() {
    return "Storage not found.\n"
        "Dont forget to initialize HttpCache package with \n"
        "HttpCache.init()";
  }
}
