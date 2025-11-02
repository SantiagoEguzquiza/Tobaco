import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tobaco/Models/Entrega.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';

/// Servicio para gestionar entregas y recorridos (online y offline)
class EntregasService {
  final ConnectivityService connectivityService;
  final DatabaseHelper databaseHelper;

  EntregasService({
    required this.connectivityService,
    required this.databaseHelper,
  });

  /// Obtiene las entregas del día para el repartidor actual
  /// Solo para vendedores-repartidores (tipo 1)
  Future<List<Entrega>> obtenerEntregasDelDia() async {
    try {
      // Intentar obtener desde el servidor si hay conexión
      if (connectivityService.isFullyConnected) {
        return await _obtenerEntregasDelServidor();
      } else {
        // Si no hay conexión, obtener desde la base de datos local
        return await _obtenerEntregasLocales();
      }
    } catch (e) {
      // En caso de error, intentar cargar desde local
      return await _obtenerEntregasLocales();
    }
  }

  /// Obtiene los recorridos (visitas) del día para el vendedor actual
  /// Solo para vendedores con camión separado (tipo 0)
  Future<List<Entrega>> obtenerRecorridosDelDia() async {
    try {
      // Intentar obtener desde el servidor si hay conexión
      if (connectivityService.isFullyConnected) {
        return await _obtenerRecorridosDelServidor();
      } else {
        // Si no hay conexión, obtener desde la base de datos local
        return await _obtenerRecorridosLocales();
      }
    } catch (e) {
      // En caso de error, intentar cargar desde local
      return await _obtenerRecorridosLocales();
    }
  }

  /// Obtiene entregas o recorridos según el tipo de usuario
  /// Para RepartidorVendedor: el endpoint /mis-entregas devuelve sus recorridos programados del día
  /// Para Repartidor: el endpoint /mis-entregas devuelve sus entregas asignadas
  Future<List<Entrega>> obtenerEntregasORecorridosDelDia() async {
    final usuario = await AuthService.getCurrentUser();
    if (usuario == null) {
      return [];
    }

    // Para ambos tipos de vendedores, usar el mismo endpoint /mis-entregas
    // El backend se encarga de devolver lo correcto según el tipo de vendedor
    return await obtenerEntregasDelDia();
  }

  /// Obtiene las entregas desde el servidor
  Future<List<Entrega>> _obtenerEntregasDelServidor() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final usuario = await AuthService.getCurrentUser();
    String tipoUsuario = "Desconocido";
    if (usuario != null) {
      if (usuario.isAdmin) {
        tipoUsuario = "Admin (Repartidor-Vendedor)";
      } else if (usuario.isEmployee) {
        // Usar los getters que existen
        if (usuario.esRepartidorVendedor) {
          tipoUsuario = "Repartidor-Vendedor";
        } else if (usuario.esVendedor) {
          tipoUsuario = "Vendedor";
        } else if (usuario.esRepartidor) {
          tipoUsuario = "Repartidor";
        } else {
          tipoUsuario = "Empleado";
        }
      }
    }
    debugPrint('🔍 Obteniendo entregas/recorridos del día para usuario: ${usuario?.userName} (tipo: $tipoUsuario)');

    final url = Apihandler.baseUrl.resolve('/api/Entregas/mis-entregas');
    debugPrint('📡 Llamando a: $url');
    
    final response = await Apihandler.client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('✅ Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      List<Entrega> entregas = jsonData.map((e) => Entrega.fromJson(e)).toList();
      debugPrint('📦 Total de entregas/recorridos recibidos: ${entregas.length}');
      
      // Guardar TODAS las entregas en cache local (para preservar estados locales)
      await _guardarEntregasEnLocal(entregas);
      
      // Recargar desde local para obtener estados actualizados
      entregas = await _obtenerEntregasLocales();
      
      // Para RepartidorVendedor, los recorridos programados NO se deben filtrar
      // Solo filtrar entregas completadas si NO son recorridos programados (VentaId == 0)
      entregas = entregas.where((e) {
        // Si es un recorrido programado (VentaId == 0), siempre mostrarlo
        if (e.ventaId == 0) {
          return true;
        }
        // Si es una entrega real, filtrar las completadas
        return !e.estaCompletada;
      }).toList();
      
      debugPrint('📋 Entregas/recorridos después del filtro: ${entregas.length}');
      
      return entregas;
    } else {
      debugPrint('❌ Error al obtener entregas: ${response.statusCode} - ${response.body}');
      throw Exception('Error al obtener entregas: ${response.statusCode}');
    }
  }

  /// Obtiene los recorridos desde el servidor
  Future<List<Entrega>> _obtenerRecorridosDelServidor() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final url = Apihandler.baseUrl.resolve('/api/Entregas/mis-recorridos');
    final response = await Apihandler.client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      List<Entrega> recorridos = jsonData.map((e) => Entrega.fromJson(e)).toList();
      // Los recorridos (visitas) no tienen estado de entrega, así que los mostramos todos
      // Guardar en cache local
      await _guardarRecorridosEnLocal(recorridos);
      
      return recorridos;
    } else {
      throw Exception('Error al obtener recorridos: ${response.statusCode}');
    }
  }

  /// Obtiene las entregas desde la base de datos local
  Future<List<Entrega>> _obtenerEntregasLocales() async {
    // Obtener usuario actual para filtrar por repartidor
    final usuario = await AuthService.getCurrentUser();
    final repartidorId = usuario?.id;
    
    return await databaseHelper.obtenerEntregasDelDia(repartidorId: repartidorId);
  }

  /// Obtiene los recorridos desde la base de datos local
  Future<List<Entrega>> _obtenerRecorridosLocales() async {
    // Obtener usuario actual para filtrar por repartidor
    final usuario = await AuthService.getCurrentUser();
    final repartidorId = usuario?.id;
    
    // Por ahora usamos la misma tabla, pero podríamos tener una tabla separada
    return await databaseHelper.obtenerEntregasDelDia(repartidorId: repartidorId);
  }

  /// Guarda las entregas en la base de datos local
  /// Primero elimina las entregas del día actual que no están en la lista del servidor
  /// (excepto las completadas localmente) para mantener el cache sincronizado
  Future<void> _guardarEntregasEnLocal(List<Entrega> entregas) async {
    // Obtener usuario actual para filtrar por repartidor
    final usuario = await AuthService.getCurrentUser();
    final repartidorId = usuario?.id;
    
    // Obtener IDs de las entregas que vienen del servidor
    final idsDelServidor = entregas.map((e) => e.id).whereType<int>().toSet();
    
    // Obtener solo las entregas del día actual del cache del usuario actual
    final entregasDelDia = await databaseHelper.obtenerEntregasDelDia(repartidorId: repartidorId);
    
    // Eliminar las entregas del cache que ya no están en el servidor
    // (excepto las que están completadas localmente y pendientes de sincronizar)
    for (var entregaCache in entregasDelDia) {
      if (entregaCache.id != null && 
          !idsDelServidor.contains(entregaCache.id) &&
          !entregaCache.estaCompletada) {
        // Esta entrega fue eliminada del servidor, eliminarla del cache
        await databaseHelper.eliminarEntregaPorId(entregaCache.id!);
      }
    }
    
    // Guardar/actualizar las entregas del servidor
    for (var entrega in entregas) {
      await databaseHelper.insertarEntrega(entrega);
    }
  }

  /// Guarda los recorridos en la base de datos local
  /// Primero elimina los recorridos del día actual que no están en la lista del servidor
  Future<void> _guardarRecorridosEnLocal(List<Entrega> recorridos) async {
    // Obtener usuario actual para filtrar por repartidor
    final usuario = await AuthService.getCurrentUser();
    final repartidorId = usuario?.id;
    
    // Obtener IDs de los recorridos que vienen del servidor
    final idsDelServidor = recorridos.map((e) => e.id).whereType<int>().toSet();
    
    // Obtener solo los recorridos del día actual del cache del usuario actual (recorridos tienen ventaId == 0)
    final entregasDelDia = await databaseHelper.obtenerEntregasDelDia(repartidorId: repartidorId);
    final recorridosDelDia = entregasDelDia.where((e) => e.ventaId == 0).toList();
    
    // Eliminar los recorridos del cache que ya no están en el servidor
    // (excepto los que están completados localmente)
    for (var recorridoCache in recorridosDelDia) {
      if (recorridoCache.id != null && 
          !idsDelServidor.contains(recorridoCache.id) &&
          !recorridoCache.estaCompletada) {
        // Este recorrido fue eliminado del servidor, eliminarlo del cache
        await databaseHelper.eliminarEntregaPorId(recorridoCache.id!);
      }
    }
    
    // Guardar/actualizar los recorridos del servidor
    for (var recorrido in recorridos) {
      await databaseHelper.insertarEntrega(recorrido);
    }
  }

  /// Actualiza el estado de una entrega
  Future<bool> actualizarEstadoEntrega(
    int entregaId,
    EstadoEntrega nuevoEstado,
  ) async {
    try {
      // Actualizar en local primero
      await databaseHelper.actualizarEstadoEntrega(entregaId, nuevoEstado);

      // Si hay conexión, sincronizar con el servidor
      if (connectivityService.isFullyConnected) {
        return await _actualizarEstadoEnServidor(entregaId, nuevoEstado);
      }

      // Si no hay conexión, marcar para sincronización posterior
      await databaseHelper.marcarEntregaParaSincronizar(entregaId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza el estado en el servidor
  Future<bool> _actualizarEstadoEnServidor(
    int entregaId,
    EstadoEntrega nuevoEstado,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) return false;

    final url = Apihandler.baseUrl.resolve('/api/Entregas/$entregaId/estado');
    
    final response = await Apihandler.client.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'estado': nuevoEstado.toJson(),
        'fechaEntrega': DateTime.now().toIso8601String(),
      }),
    );

    return response.statusCode == 200;
  }

  /// Marca una entrega como completada
  Future<bool> marcarComoEntregada(int entregaId, {String? notas}) async {
    try {
      // Actualizar en local
      await databaseHelper.marcarEntregaComoEntregada(entregaId, notas);

      // Sincronizar con servidor si hay conexión
      if (connectivityService.isFullyConnected) {
        // Actualizar estado en servidor usando endpoint de estado
        final exito = await _actualizarEstadoEnServidor(
          entregaId,
          EstadoEntrega.entregada,
        );

        if (exito) {
          await databaseHelper.marcarEntregaSincronizada(entregaId);
          return true;
        }
      } else {
        // Marcar para sincronización posterior
        await databaseHelper.marcarEntregaParaSincronizar(entregaId);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sincroniza las entregas pendientes con el servidor
  Future<int> sincronizarEntregasPendientes() async {
    try {
      if (!connectivityService.isFullyConnected) {
        return 0;
      }

      List<Entrega> entregasPendientes = 
          await databaseHelper.obtenerEntregasPendientesDeSincronizar();
      
      int sincronizadas = 0;
      
      for (var entrega in entregasPendientes) {
        bool exito = await _actualizarEstadoEnServidor(
          entrega.id!,
          entrega.estado,
        );
        
        if (exito) {
          await databaseHelper.marcarEntregaSincronizada(entrega.id!);
          sincronizadas++;
        }
      }
      
      return sincronizadas;
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene estadísticas del día
  Future<Map<String, dynamic>> obtenerEstadisticasDelDia() async {
    List<Entrega> entregas = await obtenerEntregasDelDia();
    
    int totales = entregas.length;
    int completadas = entregas.where((e) => e.estaCompletada).length;
    int pendientes = entregas.where((e) => e.estaPendiente).length;
    int parciales = entregas.where((e) => e.estado == EstadoEntrega.parcial).length;
    
    // Calcular distancia total (solo de entregas completadas)
    double distanciaTotal = 0;
    for (int i = 0; i < entregas.length - 1; i++) {
      if (entregas[i].estaCompletada && 
          entregas[i].tieneCoordenadasValidas && 
          entregas[i + 1].tieneCoordenadasValidas) {
        distanciaTotal += entregas[i].distanciaDesdeUbicacionActual ?? 0;
      }
    }
    
    return {
      'totales': totales,
      'completadas': completadas,
      'pendientes': pendientes,
      'parciales': parciales,
      'distanciaTotal': distanciaTotal,
      'porcentajeCompletado': totales > 0 ? (completadas / totales * 100).round() : 0,
    };
  }

  /// Agrega notas a una entrega
  Future<bool> agregarNotas(int entregaId, String notas) async {
    try {
      await databaseHelper.actualizarNotasEntrega(entregaId, notas);
      
      if (connectivityService.isFullyConnected) {
        final token = await AuthService.getToken();
        if (token == null) return false;

        final url = Apihandler.baseUrl.resolve('/api/Entregas/$entregaId/notas');
        
        final response = await Apihandler.client.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'notas': notas}),
        );

        return response.statusCode == 200;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene una entrega específica
  Future<Entrega?> obtenerEntrega(int entregaId) async {
    return await databaseHelper.obtenerEntregaPorId(entregaId);
  }
}

