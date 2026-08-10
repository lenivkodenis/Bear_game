@JS()
library;

import 'dart:js_interop';

@JS('bearMathDisplay.isMobile')
external JSBoolean _isMobile();

@JS('bearMathDisplay.isStandalone')
external JSBoolean _isStandalone();

@JS('bearMathDisplay.fullscreenSupported')
external JSBoolean _fullscreenSupported();

@JS('bearMathDisplay.metricsJson')
external JSString _metricsJson();

@JS('bearMathDisplay.requestImmersive')
external JSPromise<JSBoolean> _requestImmersive(JSBoolean lockLandscape);

bool get isMobile => _isMobile().toDart;
bool get isStandalone => _isStandalone().toDart;
bool get fullscreenSupported => _fullscreenSupported().toDart;
String get viewportMetricsJson => _metricsJson().toDart;

Future<bool> requestImmersive({required bool lockLandscape}) async {
  final result = await _requestImmersive(lockLandscape.toJS).toDart;
  return result.toDart;
}
