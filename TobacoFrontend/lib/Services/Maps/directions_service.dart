import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tobaco/Helpers/maps_config.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Obtiene una ruta por calles entre origen, waypoints y destino.
  /// Si [optimizeWaypoints] es true, Google puede reordenar los waypoints.
  static Future<List<LatLng>> fetchRoute({
    required LatLng origin,
    required List<LatLng> waypoints,
    required LatLng destination,
    bool optimizeWaypoints = false,
    bool detailed = true,
  }) async {
    final waypointStr = waypoints.isEmpty
        ? ''
        : '&waypoints=${optimizeWaypoints ? 'optimize:true|' : ''}${waypoints.map((w) => '${w.latitude},${w.longitude}').join('|')}';

    final uri = Uri.parse(
      '$_baseUrl?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '$waypointStr&mode=driving&units=metric&key=$directionsApiKey'
      '&alternatives=false&avoid=ferries',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Directions HTTP error: ${res.statusCode}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final status = data['status'];
    if (status != 'OK') {
      final err = data['error_message'];
      throw Exception('Directions status: $status ${err != null ? '- ' + err : ''}');
    }

    final routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) return [];

    if (!detailed) {
      final overview = routes.first['overview_polyline']['points'] as String;
      return _decodePolyline(overview);
    }

    // Ruta detallada: concatenar polylines de cada step para mayor fidelidad
    final List<LatLng> result = [];
    final legs = routes.first['legs'] as List<dynamic>;
    for (final leg in legs) {
      final steps = leg['steps'] as List<dynamic>;
      for (final step in steps) {
        final pts = step['polyline']?['points'] as String?;
        if (pts != null) {
          final decoded = _decodePolyline(pts);
          if (result.isNotEmpty && decoded.isNotEmpty &&
              result.last.latitude == decoded.first.latitude &&
              result.last.longitude == decoded.first.longitude) {
            decoded.removeAt(0); // evitar duplicado en unión
          }
          result.addAll(decoded);
        }
      }
    }
    return result;
  }

  /// Decodifica una polyline codificada de Google a una lista de LatLng.
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
}




