const bool kEnableVisualTestMode = bool.fromEnvironment(
  'ENABLE_VISUAL_TEST_MODE',
);

enum VisualTestCheckpoint {
  start('start'),
  beforeFirstObstacle('beforeFirstObstacle'),
  onFirstObstacle('onFirstObstacle'),
  beforeSecondObstacle('beforeSecondObstacle'),
  mentor('mentor'),
  taskDialog('taskDialog'),
  collision('collision');

  const VisualTestCheckpoint(this.queryValue);

  final String queryValue;
}

class VisualTestConfig {
  const VisualTestConfig({
    required this.enabled,
    required this.levelId,
    required this.checkpoint,
    required this.routePath,
  });

  const VisualTestConfig.disabled()
    : enabled = false,
      levelId = 1,
      checkpoint = VisualTestCheckpoint.start,
      routePath = '/';

  factory VisualTestConfig.fromUri(
    Uri uri, {
    bool buildEnabled = kEnableVisualTestMode,
  }) {
    if (!buildEnabled) {
      return const VisualTestConfig.disabled();
    }

    final parameters = <String, String>{
      ...uri.queryParameters,
      ..._fragmentQueryParameters(uri.fragment),
    };
    if (parameters['visualTest'] != '1') {
      return const VisualTestConfig.disabled();
    }

    final requestedLevel = int.tryParse(parameters['levelId'] ?? '1') ?? 1;
    final levelId = requestedLevel.clamp(1, 10).toInt();
    final checkpointName = parameters['checkpoint'];
    final checkpoint = VisualTestCheckpoint.values.firstWhere(
      (candidate) => candidate.queryValue == checkpointName,
      orElse: () => VisualTestCheckpoint.start,
    );

    return VisualTestConfig(
      enabled: true,
      levelId: levelId,
      checkpoint: checkpoint,
      routePath: _visualTestRoutePath(parameters, uri.fragment),
    );
  }

  final bool enabled;
  final int levelId;
  final VisualTestCheckpoint checkpoint;
  final String routePath;

  bool get showCollisionOverlay =>
      enabled && checkpoint == VisualTestCheckpoint.collision;

  bool get openTaskDialog =>
      enabled && checkpoint == VisualTestCheckpoint.taskDialog;
}

String _visualTestRoutePath(Map<String, String> parameters, String fragment) {
  final path = fragment.split('?').first;
  if (path == '/game' || path == '/map') {
    return path;
  }
  if (parameters['checkpoint'] == 'map') {
    return '/map';
  }
  if (parameters.containsKey('levelId') ||
      parameters.containsKey('checkpoint')) {
    return '/game';
  }
  return '/';
}

Map<String, String> _fragmentQueryParameters(String fragment) {
  final queryStart = fragment.indexOf('?');
  if (queryStart == -1 || queryStart == fragment.length - 1) {
    return const <String, String>{};
  }

  try {
    return Uri.splitQueryString(fragment.substring(queryStart + 1));
  } on FormatException {
    return const <String, String>{};
  }
}
