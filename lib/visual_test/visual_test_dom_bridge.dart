import 'visual_test_dom_bridge_stub.dart'
    if (dart.library.js_interop) 'visual_test_dom_bridge_web.dart'
    as platform;

void markVisualTestBooting() => platform.markVisualTestBooting();

void markVisualTestAppReady() => platform.markVisualTestAppReady();

void markVisualTestStatus(String status) =>
    platform.markVisualTestStatus(status);

void markVisualTestSceneReady({
  required int levelId,
  required String checkpoint,
  required int score,
}) {
  platform.markVisualTestSceneReady(
    levelId: levelId,
    checkpoint: checkpoint,
    score: score,
  );
}
