import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tobaco/Models/Entrega.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Models/RecorridoProgramado.dart';
import 'package:tobaco/Models/DiaSemana.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
import 'package:tobaco/Services/RecorridosProgramados_Service/recorridos_programados_service.dart';

/// Servicio para gestionar entregas y recorridos (solo llamadas al servidor)
class EntregasService {
  final RecorridosProgramadosService _recorridosService = RecorridosProgramadosService();
  
  EntregasService();

  /// Obtiene las entregas del día desde el servidor
  /// Para Vendedor: solo obtiene recorridos programados (NO entregas asignadas)
  Future<List<Entrega>> obtenerEntregasDelServidor() async {
    final usuario = await AuthService.getCurrentUser();
    final entregas = await _obtenerEntregasDelServidor();
    
    // Si es Vendedor (no Admin), solo debe ver recorridos programados, NO entregas asignadas
    // Filtrar cualquier entrega de venta asignada (ventaId > 0) que venga del servidor
    if (usuario?.esVendedor == true && !usuario!.isAdmin) {
      // Filtrar para solo mantener recorridos programados (ventaId == 0)
      entregas.removeWhere((e) => e.ventaId != null && e.ventaId! > 0);
      debugPrint('📋 Vendedor: Filtrando entregas asignadas, quedan ${entregas.length} recorridos programados');
    }
    
    return entregas;
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
    
    // Agregar timeout para evitar que se quede bloqueado si el backend está apagado
    final response = await Apihandler.client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ Timeout al conectar con el servidor');
        throw TimeoutException('No se pudo conectar con el servidor en 10 segundos');
      },
    );

    debugPrint('✅ Respuesta del servidor: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      List<Entrega> entregas = jsonData.map((e) => Entrega.fromJson(e)).toList();
      debugPrint('📦 Total de entregas/recorridos recibidos: ${entregas.length}');
      
      // Filtrar entregas del día actual
      final hoy = DateTime.now();
      final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
      
      // Para Repartidor: solo mostrar entregas de ventas asignadas (no recorridos programados)
      final esRepartidor = usuario?.esRepartidor == true && !usuario!.isAdmin;
      
      entregas = entregas.where((e) {
        // Repartidor: NO debe ver recorridos programados (ventaId == 0)
        if (esRepartidor && e.ventaId == 0) {
          return false;
        }
        
        // Verificar que la fecha de asignación sea del día actual
        if (e.fechaAsignacion.isBefore(inicioDelDia) || e.fechaAsignacion.isAfter(finDelDia)) {
          return false;
        }
        
        // Si es un recorrido programado (VentaId == 0), solo para Vendedor/RepartidorVendedor
        if (e.ventaId == 0) {
          return true; // Ya filtramos arriba si es Repartidor
        }
        
        // Para entregas completadas, verificar que la fecha de entrega sea del día actual
        if (e.estaCompletada && e.fechaEntrega != null) {
          return e.fechaEntrega!.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
                 e.fechaEntrega!.isBefore(finDelDia.add(const Duration(days: 1)));
        }
        
        // Mostrar entregas pendientes y parciales del día
        return true;
      }).toList();
      
      debugPrint('📋 Entregas/recorridos después del filtro: ${entregas.length}');
      
      return entregas;
    } else {
      debugPrint('❌ Error al obtener entregas: ${response.statusCode} - ${response.body}');
      throw Exception('Error al obtener entregas: ${response.statusCode}');
    }
  }

  /// Obtiene los recorridos programados del día actual para un vendedor
  Future<List<RecorridoProgramado>> _obtenerRecorridosProgramadosDelDia(int vendedorId) async {
    // Obtener todos los recorridos del vendedor
    final todosLosRecorridos = await _recorridosService.obtenerRecorridosPorVendedor(vendedorId);
    
    // Obtener el día actual de la semana
    final hoy = DateTime.now();
    final diaActual = _obtenerDiaSemana(hoy);
    
    // Filtrar solo los recorridos del día actual y activos
    return todosLosRecorridos.where((r) => 
      r.diaSemana == diaActual && 
      r.activo
    ).toList();
  }

  /// Obtiene el día de la semana actual
  DiaSemana _obtenerDiaSemana(DateTime fecha) {
    // DateTime.weekday: 1=Lunes, 2=Martes, ..., 7=Domingo
    // Nuestro enum: 0=Domingo, 1=Lunes, 2=Martes, ..., 6=Sábado
    int diaValue = fecha.weekday % 7; // Convierte 7 (domingo) a 0
    return DiaSemana.values.firstWhere(
      (d) => d.value == diaValue,
      orElse: () => DiaSemana.lunes,
    );
  }

  /// Convierte recorridos programados a entregas para mostrarlos en el mapa
  List<Entrega> _convertirRecorridosAEntregas(List<RecorridoProgramado> recorridos) {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    
    return recorridos.map((recorrido) {
      return Entrega(
        id: recorrido.id, // Usar el ID del recorrido programado
        ventaId: 0, // VentaId = 0 indica que es un recorrido programado
        clienteId: recorrido.clienteId,
        cliente: Cliente(
          id: recorrido.clienteId,
          nombre: recorrido.clienteNombre ?? 'Cliente',
          direccion: recorrido.clienteDireccion,
          latitud: recorrido.clienteLatitud,
          longitud: recorrido.clienteLongitud,
        ),
        latitud: recorrido.clienteLatitud,
        longitud: recorrido.clienteLongitud,
        estado: EstadoEntrega.noEntregada, // Siempre pendiente hasta que se visite
        fechaAsignacion: inicioDelDia, // Fecha del día actual
        repartidorId: recorrido.vendedorId, // El vendedor es el "repartidor" del recorrido
        orden: recorrido.orden,
      );
    }).toList();
  }

  /// Actualiza el estado de una entrega en el servidor
  Future<bool> actualizarEstadoEntrega(
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

  /// Marca una entrega como completada en el servidor
  Future<bool> marcarComoEntregada(int entregaId, {String? notas}) async {
    // Actualizar estado en servidor
    return await actualizarEstadoEntrega(
      entregaId,
      EstadoEntrega.entregada,
    );
  }


  /// Agrega notas a una entrega en el servidor
  Future<bool> agregarNotas(int entregaId, String notas) async {
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
}

