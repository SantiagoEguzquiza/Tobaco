import 'package:flutter/material.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_service.dart';

class VentasProvider with ChangeNotifier {
  final VentasService _ventasService = VentasService();

  List<Ventas> _ventas = [];

  List<dynamic> get clientes => _ventas;

  Future<List<Ventas>> obtenerVentas() async {
    try {
      _ventas = await _ventasService.obtenerVentas();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
    return _ventas;
  }

  Future<void> crearVenta(Ventas venta) async {
    try {
      await _ventasService.crearVenta(venta);
      _ventas.add(venta);
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }

  Future<void> eliminarVenta(int id) async {
    try {
      await _ventasService.eliminarVenta(id);
      _ventas.removeWhere((venta) => venta.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }


  Future<Map<String, dynamic>> obtenerVentasPaginadas(int page, int pageSize) async {
    try {
      return await _ventasService.obtenerVentasPaginadas(page, pageSize);
    } catch (e) {
      debugPrint('Error al obtener ventas paginadas: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerVentasPorCliente(
    int clienteId, {
    int pageNumber = 1,
    int pageSize = 10,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      return await _ventasService.obtenerVentasPorCliente(
        clienteId,
        pageNumber: pageNumber,
        pageSize: pageSize,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } catch (e) {
      debugPrint('Error al obtener ventas por cliente: $e');
      rethrow;
    }
  }

}
