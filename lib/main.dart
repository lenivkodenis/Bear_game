import 'package:flutter/material.dart';

import 'app.dart';
import 'visual_test/visual_test_config.dart';
import 'visual_test/visual_test_dom_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final visualTestConfig = VisualTestConfig.fromUri(Uri.base);
  if (visualTestConfig.enabled) {
    markVisualTestBooting();
  }
  runApp(BearGameApp(visualTestConfig: visualTestConfig));
}
