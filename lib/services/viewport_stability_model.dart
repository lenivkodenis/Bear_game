import 'dart:ui';

enum ViewportPhase { stable, resizing }

/// Deterministic part of the resize protocol. The UI samples rendered sizes on
/// animation frames and may settle only after two consecutive equal samples.
class ViewportStabilityModel {
  ViewportPhase phase = ViewportPhase.stable;
  Size? _lastSample;
  int _equalSamples = 0;

  bool get isStable => phase == ViewportPhase.stable;
  int get equalSamples => _equalSamples;

  void beginResize() {
    phase = ViewportPhase.resizing;
    _lastSample = null;
    _equalSamples = 0;
  }

  bool sample(Size size) {
    if (_sameSize(_lastSample, size)) {
      _equalSamples += 1;
    } else {
      _lastSample = size;
      _equalSamples = 1;
    }
    return _equalSamples >= 2;
  }

  void complete() {
    if (_equalSamples >= 2) {
      phase = ViewportPhase.stable;
    }
  }

  bool _sameSize(Size? left, Size right) {
    return left != null &&
        (left.width - right.width).abs() < 0.5 &&
        (left.height - right.height).abs() < 0.5;
  }
}
