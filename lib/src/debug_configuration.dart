abstract class DeveloperDebug {
  final bool showLog = false;
  final int level = 0;
}

class DebugProps implements DeveloperDebug {
  @override
  final bool showLog;
  @override
  final int level;

  const DebugProps({this.showLog = false, this.level = 0});
}
