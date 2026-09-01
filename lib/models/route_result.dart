import 'package:latlong2/latlong.dart';

/// A road-following route between two points: the polyline to draw plus the
/// cumulative distance along it up to each point (parallel to [points]),
/// used to interpolate a marker at constant speed along real roads instead
/// of a straight line.
class RouteResult {
  final List<LatLng> points;
  final List<double> cumulativeDistanceKm;
  final double totalDistanceKm;

  const RouteResult({
    required this.points,
    required this.cumulativeDistanceKm,
    required this.totalDistanceKm,
  });

  bool get isRoadFollowing => points.length > 2;

  /// Position at fraction [t] (0 = start, 1 = end) of the way along the
  /// route by distance travelled — not by point index — so movement speed
  /// is constant even though real road segments vary in length.
  LatLng pointAt(double t) {
    if (points.length == 1) return points.first;
    final target = totalDistanceKm * t.clamp(0.0, 1.0);

    for (var i = 1; i < cumulativeDistanceKm.length; i++) {
      if (target <= cumulativeDistanceKm[i] ||
          i == cumulativeDistanceKm.length - 1) {
        final segmentStart = cumulativeDistanceKm[i - 1];
        final segmentLength = cumulativeDistanceKm[i] - segmentStart;
        final segmentT = segmentLength == 0
            ? 0.0
            : (target - segmentStart) / segmentLength;
        final a = points[i - 1];
        final b = points[i];
        return LatLng(
          a.latitude + (b.latitude - a.latitude) * segmentT,
          a.longitude + (b.longitude - a.longitude) * segmentT,
        );
      }
    }
    return points.last;
  }
}
