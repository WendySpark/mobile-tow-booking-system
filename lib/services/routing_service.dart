import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import '../utils/distance_utils.dart';

/// Fetches an actual road-following route between two points from OSRM's
/// public routing API (no key required — same free demo server used by
/// countless open-source map prototypes). Falls back to a straight line
/// if the network call fails, so tracking never breaks, it just degrades.
///
/// Covers "make the truck go to the user on the road with proper
/// direction rather than in a straight line" — the tracking marker follows
/// [RouteResult.points], not a two-point lerp.
class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return _straightLineFallback(start, end);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] != 'Ok') return _straightLineFallback(start, end);

      final routes = body['routes'] as List;
      if (routes.isEmpty) return _straightLineFallback(start, end);

      final coordinates = (routes.first['geometry']['coordinates'] as List)
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();

      return _buildRouteResult(coordinates);
    } catch (_) {
      return _straightLineFallback(start, end);
    }
  }

  RouteResult _straightLineFallback(LatLng start, LatLng end) =>
      _buildRouteResult([start, end]);

  RouteResult _buildRouteResult(List<LatLng> points) {
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      final segment = haversineDistanceKm(
        lat1: points[i - 1].latitude,
        lng1: points[i - 1].longitude,
        lat2: points[i].latitude,
        lng2: points[i].longitude,
      );
      cumulative.add(cumulative.last + segment);
    }
    return RouteResult(
      points: points,
      cumulativeDistanceKm: cumulative,
      totalDistanceKm: cumulative.last,
    );
  }

  void dispose() => _client.close();
}
