enum TiltAction { none, save, discard }

/// Recognizes the existing quick return gesture independently of card layout.
class TiltGesture {
  TiltAction _armed = TiltAction.none;
  double _returningTime = 0;
  double progress = 0;
  TiltAction action = TiltAction.none;

  void reset() {
    _armed = TiltAction.none;
    _returningTime = 0;
    progress = 0;
    action = TiltAction.none;
  }

  void update(double normalizedTilt, double dt) {
    final tilt = normalizedTilt.clamp(-1.0, 1.0);
    final magnitude = tilt.abs();
    action = TiltAction.none;
    if (_armed != TiltAction.none) {
      if (magnitude < 0.70) {
        _returningTime += dt;
      } else {
        _returningTime = 0;
      }
      if (magnitude < 0.30) {
        if (_returningTime <= 0.200) {
          action = _armed;
          progress = action == TiltAction.save ? 1 : -1;
          return;
        }
        _armed = TiltAction.none;
        _returningTime = 0;
      } else {
        progress = _armed == TiltAction.save ? 1 : -1;
        return;
      }
    } else {
      if (tilt > 0.75) {
        _armed = TiltAction.save;
      } else if (tilt < -0.75) {
        _armed = TiltAction.discard;
      }
    }
    progress = magnitude < 0.10 && _armed == TiltAction.none
        ? 0
        : (tilt / 0.75).clamp(-1.0, 1.0);
    if (_armed == TiltAction.save) progress = 1;
    if (_armed == TiltAction.discard) progress = -1;
  }
}
