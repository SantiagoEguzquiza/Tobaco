import 'dart:convert';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Cliente.dart';

class ClienteService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Cliente>> obtenerClientes() async {
    try {
      // Realiza la solicitud usando el cliente personalizado
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Deserializa el JSON en una lista de objetos Cliente
        final List<dynamic> clientesJson = jsonDecode(response.body);

        return clientesJson.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los clientes. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener los clientes: $e');
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }

  Future<void> crearCliente(Cliente cliente) async {
    try {

      // Construye el JSON que se enviará en el body
      final Map<String, dynamic> clienteJson = {
        'nombre': cliente.nombre,
        'direccion': cliente.direccion,
        'telefono': cliente.telefono.toString(),
        'deuda': cliente.deuda.toString(),
      };

      // Realiza la solicitud usando el cliente personalizado
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Clientes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(clienteJson),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Error al guardar el cliente. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        print('Cliente guardado exitosamente');
      }
    } catch (e) {
      print('Error al guardar el cliente: $e');
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }

  Future<void> editarCliente(Cliente cliente) async {
    try {
      // Construye el JSON que se enviará en el body
      final clienteJson = cliente.toJson();

      // Realiza la solicitud usando el cliente personalizado
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Clientes/${cliente.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(clienteJson),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar el cliente. Código de estado: ${response.statusCode}');
      } else {
        print('Cliente editado exitosamente');
      }
    } catch (e) {
      print('Error al editar el cliente: $e');
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      // Realiza la solicitud usando el cliente personalizado
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
      rethrow; // Lanza la excepción para manejarla en otro lugar
    }
  }
 
}
