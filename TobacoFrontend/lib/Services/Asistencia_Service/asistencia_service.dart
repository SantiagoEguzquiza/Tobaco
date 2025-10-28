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
      print('🔍 AsistenciaService: Iniciando registro de entrada para usuario $userId');
      
      // Obtener ubicación
      print('📍 AsistenciaService: Obteniendo ubicación...');
      final locationData = await _getLocationData();
      print('📍 AsistenciaService: Ubicación obtenida: ${locationData['address']}');

      final registrarEntradaDto = RegistrarEntradaDTO(
        userId: userId,
        ubicacionEntrada: locationData['address'],
        latitudEntrada: locationData['latitude'],
        longitudEntrada: locationData['longitude'],
      );

      print('📡 AsistenciaService: Preparando petición al backend...');
      final headers = await AuthService.getAuthHeaders();
      print('📡 AsistenciaService: Headers obtenidos');
      
      final url = Apihandler.baseUrl.resolve('$_baseEndpoint/registrar-entrada');
      print('📡 AsistenciaService: URL: $url');
      print('📡 AsistenciaService: Body: ${jsonEncode(registrarEntradaDto.toJson())}');
      
      final response = await Apihandler.client.post(
        url,
        headers: headers,
        body: jsonEncode(registrarEntradaDto.toJson()),
      ).timeout(_timeoutDuration);

      print('📡 AsistenciaService: Respuesta recibida: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ AsistenciaService: Entrada registrada exitosamente');
        return Asistencia.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        print('❌ AsistenciaService: Error 400: ${errorData['message']}');
        throw Exception(errorData['message'] ?? 'Error al registrar la entrada');
      } else {
        print('❌ AsistenciaService: Error del servidor: ${response.statusCode}');
        throw Exception('Error del servidor. Intenta nuevamente más tarde.');
      }
    } catch (e) {
      print('❌ AsistenciaService: Excepción capturada: $e');
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
      print('📍 _getLocationData: Iniciando obtención de ubicación...');
      
      // Verificar si los servicios de ubicación están habilitados
      print('📍 _getLocationData: Verificando servicios de ubicación...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(Duration(seconds: 3), onTimeout: () {
        print('⏱️ _getLocationData: Timeout verificando servicios');
        return false;
      });
      
      if (!serviceEnabled) {
        print('⚠️ _getLocationData: Servicios de ubicación deshabilitados');
        return {
          'latitude': null,
          'longitude': null,
          'address': 'Ubicación no disponible (Windows Desktop)',
        };
      }

      print('📍 _getLocationData: Verificando permisos...');
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(Duration(seconds: 3), onTimeout: () {
        print('⏱️ _getLocationData: Timeout verificando permisos');
        return LocationPermission.denied;
      });
      
      if (permission == LocationPermission.denied) {
        print('📍 _getLocationData: Solicitando permisos...');
        permission = await Geolocator.requestPermission()
            .timeout(Duration(seconds: 5), onTimeout: () {
          print('⏱️ _getLocationData: Timeout solicitando permisos');
          return LocationPermission.denied;
        });
        
        if (permission == LocationPermission.denied) {
          print('⚠️ _getLocationData: Permisos denegados');
          return {
            'latitude': null,
            'longitude': null,
            'address': 'Ubicación no disponible',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ _getLocationData: Permisos denegados permanentemente');
        return {
          'latitude': null,
          'longitude': null,
          'address': 'Ubicación no disponible',
        };
      }

      print('📍 _getLocationData: Obteniendo posición actual...');
      // Obtener posición actual con timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      ).timeout(Duration(seconds: 7), onTimeout: () {
        print('⏱️ _getLocationData: Timeout obteniendo posición');
        throw Exception('Timeout obteniendo ubicación');
      });

      print('✅ _getLocationData: Posición obtenida: ${position.latitude}, ${position.longitude}');

      // Intentar obtener la dirección
      String address = 'Ubicación obtenida';
      try {
        print('📍 _getLocationData: Obteniendo dirección...');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(Duration(seconds: 3), onTimeout: () {
          print('⏱️ _getLocationData: Timeout obteniendo dirección');
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
          print('✅ _getLocationData: Dirección obtenida: $address');
        } else {
          address = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        print('⚠️ _getLocationData: Error obteniendo dirección: $e');
        // Si falla la geocodificación, usar las coordenadas
        address = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
      }

      return {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'address': address,
      };
    } catch (e) {
      print('❌ _getLocationData: Error general: $e');
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

