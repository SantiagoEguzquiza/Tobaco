import 'dart:convert';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Producto.dart';

class ProductoService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Producto>> obtenerProductos() async {
    try {
      // Realiza la solicitud usando el cliente personalizado
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Productos'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Deserializa el JSON en una lista de objetos Producto
        final List<dynamic> productosJson = jsonDecode(response.body);

        return productosJson.map((json) => Producto.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los productos. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener los productos: $e');
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }

  Future<void> crearProducto(Producto producto) async {
    try {
      // Construye el JSON que se enviará en el body
      final Map<String, dynamic> productoJson = producto.toJson();

      // Realiza la solicitud usando el cliente personalizado
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Productos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productoJson),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Error al guardar el producto. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        print('Producto guardado exitosamente');
      }
    } catch (e) {
      print('Error al guardar el producto: $e');
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }

  Future<void> editarProducto(Producto producto) async {
    try {
      // Construye el JSON que se enviará en el body
      final productoJson = producto.toJson();

      // Realiza la solicitud usando el cliente personalizado
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Productos/${producto.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productoJson),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar el producto. Código de estado: ${response.statusCode}');
      } else {
        print('Producto editado exitosamente');
      }
    } catch (e) {
      print('Error al editar el producto: $e');
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }

  Future<void> eliminarProducto(int id) async {
    try {
      // Realiza la solicitud usando el cliente personalizado
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Productos/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar el producto. Código de estado: ${response.statusCode}');
      } else {
        print('Producto eliminado exitosamente');
      }
    } catch (e) {
      print('Error al eliminar el producto: $e');
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }
}
