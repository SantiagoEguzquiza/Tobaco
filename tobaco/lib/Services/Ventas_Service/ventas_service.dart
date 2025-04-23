import 'dart:convert';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Ventas.dart';

class VentasService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Ventas>> obtenerVentas() async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Pedidos'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> ventasJson = jsonDecode(response.body);
        return ventasJson.map((json) => Ventas.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener las ventas. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener las ventas: $e');
      rethrow;
    }
  }

  Future<void> crearVenta(Ventas venta) async {
    try {
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Pedidos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(venta.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Error al guardar la venta. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        print('Venta guardada exitosamente');
      }
    } catch (e) {
      print('Error al guardar la venta: $e');
      rethrow;
    }
  }

  Future<void> editarVenta(Ventas venta) async {
    try {
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Pedidos/${venta.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(venta.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar la venta. Código de estado: ${response.statusCode}');
      } else {
        print('Venta editada exitosamente');
      }
    } catch (e) {
      print('Error al editar la venta: $e');
      rethrow;
    }
  }

  Future<void> eliminarVenta(int id) async {
    try {
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Pedidos/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar el cliente. Código de estado: ${response.statusCode}');
      } else {
        print('Cliente eliminado exitosamente');
      }
    } catch (e) {
      print('Error al eliminar el cliente: $e');
      rethrow;
    }
  }
}
