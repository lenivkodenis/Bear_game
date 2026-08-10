import 'dart:js_interop';

@JS('document.body.setAttribute')
external void _setBodyAttribute(JSString name, JSString value);

void markVisualTestBooting() {
  _setAttribute('data-bear-visual-test', '1');
  _setAttribute('data-bear-ready', 'booting');
}

void markVisualTestAppReady() {
  _setAttribute('data-bear-ready', 'app');
}

void markVisualTestStatus(String status) {
  _setAttribute('data-bear-ready', status);
}

void markVisualTestSceneReady({
  required int levelId,
  required String checkpoint,
  required int score,
}) {
  _setAttribute('data-bear-level', '$levelId');
  _setAttribute('data-bear-checkpoint', checkpoint);
  _setAttribute('data-bear-score', '$score');
  _setAttribute('data-bear-ready', 'scene');
}

void _setAttribute(String name, String value) {
  _setBodyAttribute(name.toJS, value.toJS);
}
