import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_tow_booking_system/models/route_result.dart';

void main() {
  RouteResult routeOf(List<LatLng> points) {
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      const Distance distance = Distance();
      cumulative.add(cumulative.last + distance.as(LengthUnit.Kilometer, points[i - 1], points[i]));
    }
    return RouteResult(points: points, cumulativeDistanceKm: cumulative, totalDistanceKm: cumulative.last);
  }

  group('RouteResult.pointAt', () {
    test('t=0 returns the start point', () {
      final route = routeOf([const LatLng(3.0, 101.0), const LatLng(3.1, 101.1)]);
      expect(route.pointAt(0), const LatLng(3.0, 101.0));
    });

    test('t=1 returns the end point', () {
      final route = routeOf([const LatLng(3.0, 101.0), const LatLng(3.1, 101.1)]);
      final result = route.pointAt(1);
      expect(result.latitude, closeTo(3.1, 0.0001));
      expect(result.longitude, closeTo(101.1, 0.0001));
    });

    test('t is clamped for out-of-range input', () {
      final route = routeOf([const LatLng(3.0, 101.0), const LatLng(3.1, 101.1)]);
      expect(route.pointAt(-0.5), route.pointAt(0));
      expect(route.pointAt(1.5), route.pointAt(1));
    });

    test('interpolates through an intermediate waypoint, not just endpoints', () {
      // Three collinear-ish points where the middle segment is much shorter
      // than the first — distance-weighted interpolation should still land
      // near the midpoint of the *second* segment at t close to 1, not
      // overshoot past it the way naive index-based interpolation would.
      final route = routeOf([
        const LatLng(3.0, 101.0),
        const LatLng(3.09, 101.0), // long first leg
        const LatLng(3.10, 101.0), // short second leg
      ]);

      // Halfway through total distance should land inside the first leg,
      // since it's ~9x longer than the second.
      final midpoint = route.pointAt(0.5);
      expect(midpoint.latitude, lessThan(3.09));
      expect(midpoint.latitude, greaterThan(3.0));
    });

    test('a single-point route returns that point regardless of t', () {
      final route = routeOf([const LatLng(3.0, 101.0)]);
      expect(route.pointAt(0.5), const LatLng(3.0, 101.0));
    });

    test('isRoadFollowing is false for a straight-line fallback (2 points)', () {
      final route = routeOf([const LatLng(3.0, 101.0), const LatLng(3.1, 101.1)]);
      expect(route.isRoadFollowing, isFalse);
    });

    test('isRoadFollowing is true for a multi-point road route', () {
      final route = routeOf([
        const LatLng(3.0, 101.0),
        const LatLng(3.05, 101.02),
        const LatLng(3.1, 101.1),
      ]);
      expect(route.isRoadFollowing, isTrue);
    });
  });
}
