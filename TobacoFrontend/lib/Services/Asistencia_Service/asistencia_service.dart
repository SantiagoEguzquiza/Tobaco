import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../Helpers/api_handler.dart';
import '../../Models/Asistencia.dart';
import '../Auth_Service/auth_service.dart';

class AsistenciaService {
  static const String _baseEndpoint = '/api/Asistencia';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Registrar entrada
  static Future<Asistencia> registrarEntrada(int userId) async {
    try {
      
      
      // Obtener ubicación
      
      final locationData = await _getLocationData();
      

      final registrarEntradaDto = RegistrarEntradaDTO(
        userId: userId,
        ubicacionEntrada: locationData['address'],
        latitudEntrada: locationData['latitude'],
        longitudEntrada: locationData['longitude'],
      );

      
      final headers = await AuthService.getAuthHeaders();
      
      
      final url = Apihandler.baseUrl.resolve('$_baseEndpoint/registrar-entrada');
      
      
      
      final response = await Apihandler.client.post(
        url,
        headers: headers,
        body: jsonEncode(registrarEntradaDto.toJson()),
      ).timeout(_timeoutDuration);

      

      if (response.statusCode == 200) {
        
        return Asistencia.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        
        throw Exception(errorData['message'] ?? 'Error al registrar la entrada');
      } else {
        
        throw Exception('Error del servidor. Intenta nuevamente más tarde.');
      }
    } catch (e) {
      
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      throw Exception(errorMessage);
    }
  }

  // Registrar salida
  static Future<Asistencia> registrarSalida(int asistenciaId) async {
    try {
      // Obtener ubicación
      final locationData = await _getLocationData();

      final registrarSalidaDto = RegistrarSalidaDTO(
        asistenciaId: asistenciaId,
        ubicacionSalida: locationData['address'],
        latitudSalida: locationData['latitude'],
        longitudSalida: locationData['longitude'],
      );

      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.post(
        Apihandler.baseUrl.resolve('$_baseEndpoint/registrar-salida'),
        headers: headers,
        body: jsonEncode(registrarSalidaDto.toJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return Asistencia.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Asistencia no encontrada');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al registrar la salida');
      } else {
        throw Exception('Error del servidor. Intenta nuevamente más tarde.');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      throw Exception(errorMessage);
    }
  }

  // Obtener asistencia activa del usuario
  static Future<Asistencia?> getAsistenciaActiva(int userId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Apihandler.baseUrl.resolve('$_baseEndpoint/activa/$userId'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return Asistencia.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null; // No hay asistencia activa
      } else {
        throw Exception('Error al obtener la asistencia activa');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        return null; // En caso de error de conexión, retornar null
      }
      return null;
    }
  }

  // Obtener todas las asistencias del usuario
  static Future<List<Asistencia>> getAsistenciasByUserId(int userId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Apihandler.baseUrl.resolve('$_baseEndpoint/usuario/$userId'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener las asistencias');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      throw Exception(errorMessage);
    }
  }

  // Obtener asistencias por rango de fechas
  static Future<List<Asistencia>> getAsistenciasByDateRange(
    int userId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final queryParams = {
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
      };

      final uri = Apihandler.baseUrl.resolve('$_baseEndpoint/usuario/$userId/rango')
          .replace(queryParameters: queryParams);

      final response = await Apihandler.client.get(
        uri,
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener las asistencias');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      throw Exception(errorMessage);
    }
  }

  // Obtener todas las asistencias (solo para administradores)
  static Future<List<Asistencia>> getAllAsistencias() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Apihandler.baseUrl.resolve('$_baseEndpoint/todas'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener las asistencias');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      throw Exception(errorMessage);
    }
  }

  // Obtener ubicación del dispositivo
  static Future<Map<String, String?>> _getLocationData() async {
    try {
      
      
      // Verificar si los servicios de ubicación están habilitados
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(Duration(seconds: 3), onTimeout: () {
        
        return false;
      });
      
      if (!serviceEnabled) {
        
        return {
          'latitude': null,
          'longitude': null,
          'address': 'Ubicación no disponible (Windows Desktop)',
        };
      }

      
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(Duration(seconds: 3), onTimeout: () {
        
        return LocationPermission.denied;
      });
      
      if (permission == LocationPermission.denied) {
        
        permission = await Geolocator.requestPermission()
            .timeout(Duration(seconds: 5), onTimeout: () {
          
          return LocationPermission.denied;
        });
        
        if (permission == LocationPermission.denied) {
          
          return {
            'latitude': null,
            'longitude': null,
            'address': 'Ubicación no disponible',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        
        return {
          'latitude': null,
          'longitude': null,
          'address': 'Ubicación no disponible',
        };
      }

      
      // Obtener posición actual con timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      ).timeout(Duration(seconds: 7), onTimeout: () {
        
        throw Exception('Timeout obteniendo ubicación');
      });

      

      // Intentar obtener la dirección
      String address = 'Ubicación obtenida';
      try {
        
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(Duration(seconds: 3), onTimeout: () {
          
          return [];
        });

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          
        } else {
          address = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        
        // Si falla la geocodificación, usar las coordenadas
        address = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
      }

      return {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'address': address,
      };
    } catch (e) {
      
      // En lugar de fallar, continuar sin ubicación
      return {
        'latitude': null,
        'longitude': null,
        'address': 'Ubicación no disponible',
      };
    }
  }

  // Verificar si los servicios de ubicación están disponibles
  static Future<bool> isLocationServiceAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }
}

