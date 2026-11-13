/// Fork: whether Measure records taps (tyne-chat/tyne#620).
///
/// To find the tapped widget, Measure's tap tracking walks the whole widget
/// tree on every tap (`MsrGestureDetector._handleClick` in measure_flutter
/// 0.9.1), and only afterwards decides whether to keep the snapshot. That took
/// about 26 ms per tap on a fast phone, three frames at 120 Hz. Tyne uses
/// Measure for crash reports, so tap tracking is off: `FluxerMeasureRoot`
/// leaves `MeasureWidget` out of the tree. Without it, screen views carry no
/// layout snapshot either. Crash and error reports, and the screen views
/// themselves, are unaffected.
///
/// A build for one user's reproduction can turn it back on with
/// `--dart-define=TYNE_MEASURE_TAP_TRACKING=true`.
// ignore: do_not_use_environment -- compile-time switch for a reproduction build
const bool forkMeasureTapTracking = bool.fromEnvironment(
  'TYNE_MEASURE_TAP_TRACKING',
);
