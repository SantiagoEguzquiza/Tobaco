import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tobaco/Models/Entrega.dart';

/// Servicio para manejar geolocalización y cálculo de rutas
class UbicacionService {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _ultimaPosicion;

  /// Obtiene la última posición conocida
  Position? get ultimaPosicion => _ultimaPosicion;

  /// Verifica si los servicios de ubicación están habilitados
  Future<bool> verificarServicioUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    return true;
  }

  /// Solicita permisos de ubicación
  Future<bool> solicitarPermisos() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Los permisos están denegados permanentemente
      return false;
    }
    
    return true;
  }

  /// Obtiene la posición actual del dispositivo
  Future<Position?> obtenerPosicionActual() async {
    try {
      // Verificar servicio
      bool serviceEnabled = await verificarServicioUbicacion();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

      // Verificar permisos
      bool permisosOk = await solicitarPermisos();
      if (!permisosOk) {
        throw Exception('Permisos de ubicación denegados');
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _ultimaPosicion = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Inicia el seguimiento de ubicación en tiempo real
  Stream<Position> iniciarSeguimientoUbicacion() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) {
      _ultimaPosicion = position;
      return position;
    });
  }

  /// Detiene el seguimiento de ubicación
  void detenerSeguimientoUbicacion() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Calcula la distancia entre dos puntos (en kilómetros)
  double calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convertir a km
  }

  /// Calcula la distancia desde la posición actual a una coordenada
  double? calcularDistanciaDesdeActual(double lat, double lon) {
    if (_ultimaPosicion == null) return null;
    return calcularDistancia(
      _ultimaPosicion!.latitude,
      _ultimaPosicion!.longitude,
      lat,
      lon,
    );
  }

  /// Geocodifica una dirección (convierte dirección en coordenadas)
  Future<Map<String, double>?> geocodificarDireccion(String direccion) async {
    try {
      List<Location> locations = await locationFromAddress(direccion);
      if (locations.isNotEmpty) {
        return {
          'latitud': locations.first.latitude,
          'longitud': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Geocodificación inversa (coordenadas a dirección)
  Future<String?> obtenerDireccionDesdeCoordenadas(
    double lat,
    double lon,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Ordena las entregas por cercanía a la posición actual
  List<Entrega> ordenarEntregasPorCercania(
    List<Entrega> entregas,
    Position? posicionActual,
  ) {
    if (posicionActual == null) return entregas;

    // Crear una copia de la lista
    List<Entrega> entregasOrdenadas = List.from(entregas);

    // Calcular distancia para cada entrega
    for (var entrega in entregasOrdenadas) {
      if (entrega.tieneCoordenadasValidas) {
        entrega.distanciaDesdeUbicacionActual = calcularDistancia(
          posicionActual.latitude,
          posicionActual.longitude,
          entrega.latitud!,
          entrega.longitud!,
        );
      }
    }

    // Ordenar por distancia (las que no tienen coordenadas van al final)
    entregasOrdenadas.sort((a, b) {
      if (a.distanciaDesdeUbicacionActual == null) return 1;
      if (b.distanciaDesdeUbicacionActual == null) return -1;
      return a.distanciaDesdeUbicacionActual!
          .compareTo(b.distanciaDesdeUbicacionActual!);
    });

    // Actualizar el orden
    for (int i = 0; i < entregasOrdenadas.length; i++) {
      entregasOrdenadas[i].orden = i + 1;
    }

    return entregasOrdenadas;
  }

  /// Calcula la ruta óptima simple (algoritmo del vecino más cercano)
  List<Entrega> calcularRutaOptima(
    List<Entrega> entregas,
    Position posicionActual,
  ) {
    if (entregas.isEmpty) return [];

    List<Entrega> entregasPendientes = entregas
        .where((e) => e.tieneCoordenadasValidas && !e.estaCompletada)
        .toList();

    if (entregasPendientes.isEmpty) return entregas;

    List<Entrega> rutaOptimizada = [];
    double latActual = posicionActual.latitude;
    double lonActual = posicionActual.longitude;

    while (entregasPendientes.isNotEmpty) {
      // Encontrar la entrega más cercana
      Entrega? masCercana;
      double distanciaMinima = double.infinity;

      for (var entrega in entregasPendientes) {
        double distancia = calcularDistancia(
          latActual,
          lonActual,
          entrega.latitud!,
          entrega.longitud!,
        );

        if (distancia < distanciaMinima) {
          distanciaMinima = distancia;
          masCercana = entrega;
        }
      }

      if (masCercana != null) {
        masCercana.distanciaDesdeUbicacionActual = distanciaMinima;
        rutaOptimizada.add(masCercana);
        entregasPendientes.remove(masCercana);
        
        // Actualizar posición actual para la próxima iteración
        latActual = masCercana.latitud!;
        lonActual = masCercana.longitud!;
      }
    }

    // Agregar las entregas ya completadas al final
    rutaOptimizada.addAll(
      entregas.where((e) => e.estaCompletada).toList(),
    );

    // Actualizar orden
    for (int i = 0; i < rutaOptimizada.length; i++) {
      rutaOptimizada[i].orden = i + 1;
    }

    return rutaOptimizada;
  }

  /// Calcula la distancia total de la ruta
  double calcularDistanciaTotal(List<Entrega> entregas, Position? inicio) {
    if (entregas.isEmpty || inicio == null) return 0;

    double distanciaTotal = 0;
    double latActual = inicio.latitude;
    double lonActual = inicio.longitude;

    for (var entrega in entregas) {
      if (entrega.tieneCoordenadasValidas) {
        distanciaTotal += calcularDistancia(
          latActual,
          lonActual,
          entrega.latitud!,
          entrega.longitud!,
        );
        latActual = entrega.latitud!;
        lonActual = entrega.longitud!;
      }
    }

    return distanciaTotal;
  }

  /// Calcula el tiempo estimado de viaje (asumiendo 40 km/h promedio en ciudad)
  Duration calcularTiempoEstimado(double distanciaKm) {
    const velocidadPromedioKmH = 40.0;
    double horas = distanciaKm / velocidadPromedioKmH;
    return Duration(minutes: (horas * 60).round());
  }

  /// Obtiene la siguiente entrega pendiente
  Entrega? obtenerSiguienteEntrega(List<Entrega> entregas) {
    try {
      return entregas.firstWhere(
        (e) => e.estaPendiente && e.tieneCoordenadasValidas,
      );
    } catch (e) {
      return null;
    }
  }

  /// Limpia recursos
  void dispose() {
    detenerSeguimientoUbicacion();
  }
}

