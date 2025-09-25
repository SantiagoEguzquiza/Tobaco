import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();

  List<Cliente> _clientes = [];
  List<Cliente> _clientesConDeuda = [];

  List<dynamic> get clientes => _clientes;
  List<dynamic> get clientesConDeuda => _clientesConDeuda;

  Future<List<Cliente>> obtenerClientes() async {
    try {
      _clientes = await _clienteService.obtenerClientes();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
    return _clientes;
  }

  Future<Cliente?> crearCliente(Cliente cliente) async {
    try {
      final clienteCreado = await _clienteService.crearCliente(cliente);
      _clientes.add(clienteCreado);
      notifyListeners();
      return clienteCreado;
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      await _clienteService.eliminarCliente(id);
      _clientes.removeWhere((cliente) => cliente.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> editarCliente(Cliente cliente) async {
    try {
      await _clienteService.editarCliente(cliente);
      int index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = cliente;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<List<Cliente>> buscarClientes(String query) async {
    try {
      final resultados = await _clienteService.buscarClientes(query);

      // Ordenar: primero los que empiezan con el query, luego los que lo contienen
      final queryLower = query.toLowerCase();
      final empiezaCon = resultados.where((c) => c.nombre.toLowerCase().startsWith(queryLower)).toList();
      final contiene = resultados.where((c) =>
          !c.nombre.toLowerCase().startsWith(queryLower) &&
          c.nombre.toLowerCase().contains(queryLower)).toList();

      _clientes = [...empiezaCon, ...contiene];
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
    return _clientes;
  }

  Future<List<Cliente>> obtenerClientesConDeuda() async {
    try {
      _clientesConDeuda = await _clienteService.obtenerClientesConDeuda();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
    }
    return _clientesConDeuda;
  }
}
