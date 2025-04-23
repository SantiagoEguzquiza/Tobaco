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
      print('Error: $e');
    }
    return _ventas;
  }

  Future<void> crearCliente(Ventas venta) async {
    try {
      await _ventasService.crearVenta(venta);
      _ventas.add(venta);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      await _ventasService.eliminarVenta(id);
      _ventas.removeWhere((venta) => venta.id == id);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> editarCliente(Ventas venta) async {
    try {
      await _ventasService.editarVenta(venta);
      int index = _ventas.indexWhere((c) => c.id == venta.id);
      if (index != -1) {
        _ventas[index] = venta;
        notifyListeners();
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  


}
