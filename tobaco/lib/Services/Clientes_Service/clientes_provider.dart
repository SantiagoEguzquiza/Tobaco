import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();

  List<Cliente> _clientes = [];

  List<dynamic> get clientes => _clientes;

  Future<List<Cliente>> obtenerClientes() async {
    try {
      _clientes = await _clienteService.obtenerClientes();
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
    return _clientes;
  }

  Future<void> crearCliente(Cliente cliente) async {
    try {
      await _clienteService.crearCliente(cliente);
      _clientes.add(cliente);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      await _clienteService.eliminarCliente(id);
      _clientes.removeWhere((cliente) => cliente.id == id);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
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
      print('Error: $e');
    }
  }

  Future<List<Cliente>> buscarClientes(String query) async {
    try {
      _clientes = await _clienteService.buscarClientes(query);
      notifyListeners();
    } catch (e) {
      print('Error: $e');
    }
    return _clientes;
  }
}
