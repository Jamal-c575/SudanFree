import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteData {
  final List<LatLng> points;
  final double distanceKm;

  RouteData({required this.points, required this.distanceKm});
}

class OSRMService {
  static Future<RouteData?> getRoute(LatLng start, LatLng end) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coords = geometry['coordinates'] as List;

          final points = coords.map((c) => LatLng(c[1], c[0])).toList();
          final distanceKm = (route['distance'] as num) / 1000.0;

          return RouteData(points: points, distanceKm: distanceKm);
        }
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
    return null;
  }
}
