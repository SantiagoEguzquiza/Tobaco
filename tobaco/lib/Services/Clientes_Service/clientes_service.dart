import 'dart:convert';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Cliente.dart';

class ClienteService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Cliente>> obtenerClientes() async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> clientesJson = jsonDecode(response.body);
        return clientesJson.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los clientes. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener los clientes: $e');
      rethrow;
    }
  }

  Future<void> crearCliente(Cliente cliente) async {
    try {
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Clientes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cliente.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al guardar el cliente. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        print('Cliente guardado exitosamente');
      }
    } catch (e) {
      print('Error al guardar el cliente: $e');
      rethrow;
    }
  }

  Future<void> editarCliente(Cliente cliente) async {
    try {
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Clientes/${cliente.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cliente.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar el cliente. Código de estado: ${response.statusCode}');
      } else {
        print('Cliente editado exitosamente');
      }
    } catch (e) {
      print('Error al editar el cliente: $e');
      rethrow;
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Clientes/$id'),
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

  Future<List<Cliente>> buscarClientes(String nombre) async {
  final response = await Apihandler.client.get(
    Uri.parse('$baseUrl/Clientes/buscar?query=$nombre'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Cliente.fromJson(json)).toList();
  } else {
    throw Exception('Error al buscar clientes');
  }
}
}
