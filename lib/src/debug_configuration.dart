abstract class DeveloperDebug {
  final bool showLog = false;
  final int level = 0;
}

class HttpLog implements DeveloperDebug {
  ///if you set as true. it will show the log of the fetching data
  @override
  final bool showLog;
  @override
  final int level;

  const HttpLog({this.showLog = false, this.level = 0});
}
