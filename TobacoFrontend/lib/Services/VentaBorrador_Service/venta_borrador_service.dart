import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tobaco/Models/VentaBorrador.dart';

/// Servicio para gestionar la persistencia de ventas en borrador
/// Utiliza SharedPreferences para almacenamiento local
class VentaBorradorService {
  static const String _keyBorrador = 'venta_borrador';
  
  /// Guarda el borrador de venta en almacenamiento local
  /// Retorna true si se guardó exitosamente
  Future<bool> guardarBorrador(VentaBorrador borrador) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final borradorJson = json.encode(borrador.toJson());
      return await prefs.setString(_keyBorrador, borradorJson);
    } catch (e) {
      print('Error al guardar borrador: $e');
      return false;
    }
  }

  /// Carga el borrador de venta desde almacenamiento local
  /// Retorna null si no existe borrador o hubo error
  Future<VentaBorrador?> cargarBorrador() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final borradorJson = prefs.getString(_keyBorrador);
      
      if (borradorJson == null) {
        return null;
      }

      final borradorMap = json.decode(borradorJson) as Map<String, dynamic>;
      return VentaBorrador.fromJson(borradorMap);
    } catch (e) {
      print('Error al cargar borrador: $e');
      return null;
    }
  }

  /// Elimina el borrador de venta del almacenamiento local
  /// Retorna true si se eliminó exitosamente
  Future<bool> eliminarBorrador() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_keyBorrador);
    } catch (e) {
      print('Error al eliminar borrador: $e');
      return false;
    }
  }

  /// Verifica si existe un borrador guardado
  /// Retorna true si existe un borrador
  Future<bool> existeBorrador() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyBorrador);
    } catch (e) {
      print('Error al verificar borrador: $e');
      return false;
    }
  }

  /// Actualiza la fecha de última modificación del borrador actual
  /// Útil para tracking de actividad
  Future<bool> actualizarFechaModificacion() async {
    try {
      final borrador = await cargarBorrador();
      if (borrador == null) return false;

      final borradorActualizado = borrador.copyWith(
        fechaUltimaModificacion: DateTime.now(),
      );
      
      return await guardarBorrador(borradorActualizado);
    } catch (e) {
      print('Error al actualizar fecha de modificación: $e');
      return false;
    }
  }
}

