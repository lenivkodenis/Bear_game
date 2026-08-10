import 'mobile_display_service_stub.dart'
    if (dart.library.js_interop) 'mobile_display_service_web.dart'
    as platform;

/// Cross-platform facade for browser display capabilities. Non-web builds keep
/// the same API and simply report that the capabilities are unavailable.
class MobileDisplayService {
  MobileDisplayService._();

  static final MobileDisplayService instance = MobileDisplayService._();

  bool get isMobile => platform.isMobile;
  bool get isStandalone => platform.isStandalone;
  bool get fullscreenSupported => platform.fullscreenSupported;

  String get viewportMetricsJson => platform.viewportMetricsJson;

  /// Must be invoked directly from a tap handler so mobile browsers retain the
  /// user activation required by the Fullscreen and Orientation APIs.
  Future<bool> requestImmersive({bool lockLandscape = false}) {
    return platform.requestImmersive(lockLandscape: lockLandscape);
  }
}
