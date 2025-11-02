import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';

class ClienteProvider with ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  final DatosCacheService _cacheService = DatosCacheService();

  List<Cliente> _clientes = [];
  List<Cliente> _clientesConDeuda = [];

  List<dynamic> get clientes => _clientes;
  List<dynamic> get clientesConDeuda => _clientesConDeuda;

  /// Obtiene clientes: intenta del servidor, si falla usa caché
  Future<List<Cliente>> obtenerClientes() async {
    print('📡 ClienteProvider: Intentando obtener clientes del servidor...');
    
    try {
      // Intentar obtener del servidor con timeout (500ms para ser más rápido en offline)
      _clientes = await _clienteService.obtenerClientes()
          .timeout(Duration(milliseconds: 500));
      
      print('✅ ClienteProvider: ${_clientes.length} clientes obtenidos del servidor');
      
      // Guardar en caché para uso offline (en background)
      if (_clientes.isNotEmpty) {
        await _cacheService.guardarClientesEnCache(_clientes);
        print('✅ ClienteProvider: ${_clientes.length} clientes guardados en caché');
      }
      
    } catch (e) {
      print('⚠️ ClienteProvider: Error obteniendo del servidor: $e');
      print('📦 ClienteProvider: Cargando clientes del caché...');
      
      // Si falla, cargar del caché
      _clientes = await _cacheService.obtenerClientesDelCache();
      
      if (_clientes.isEmpty) {
        print('❌ ClienteProvider: No hay clientes en caché');
        throw Exception('No hay clientes disponibles offline. Conecta para sincronizar.');
      } else {
        print('✅ ClienteProvider: ${_clientes.length} clientes cargados del caché');
      }
    }

    notifyListeners();
    return _clientes;
  }

  Future<Cliente?> crearCliente(Cliente cliente) async {
    try {
      final clienteCreado = await _clienteService.crearCliente(cliente);
      _clientes.add(clienteCreado);
      // Guardar en caché para que esté disponible offline
      await _cacheService.guardarClientesEnCache(_clientes);
      notifyListeners();
      return clienteCreado;
    } catch (e) {
      debugPrint('Error: $e');
      rethrow; // Relanzar la excepción para que se maneje en la UI
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

  /// Busca clientes por nombre (con soporte offline)
  Future<List<Cliente>> buscarClientes(String query) async {
    List<Cliente> resultados;
    
    try {
      // Intentar buscar en el servidor con timeout (500ms para ser más rápido en offline)
      print('📡 ClienteProvider: Buscando clientes en servidor...');
      resultados = await _clienteService.buscarClientes(query)
          .timeout(Duration(milliseconds: 500));
      
      print('✅ ClienteProvider: ${resultados.length} clientes encontrados en servidor');
    } catch (e) {
      print('⚠️ ClienteProvider: Error buscando en servidor: $e');
      print('📦 ClienteProvider: Buscando en caché local...');
      
      // Si falla, buscar en caché local
      final todosLosClientes = await _cacheService.obtenerClientesDelCache();
      
      // Filtrar por nombre
      final queryLower = query.toLowerCase();
      resultados = todosLosClientes
          .where((c) => c.nombre.toLowerCase().contains(queryLower))
          .toList();
      
      print('✅ ClienteProvider: ${resultados.length} clientes encontrados en caché');
    }

    // Ordenar: primero los que empiezan con el query, luego los que lo contienen
    final queryLower = query.toLowerCase();
    final empiezaCon = resultados
        .where((c) => c.nombre.toLowerCase().startsWith(queryLower))
        .toList();
    final contiene = resultados
        .where((c) => !c.nombre.toLowerCase().startsWith(queryLower) &&
            c.nombre.toLowerCase().contains(queryLower))
        .toList();

    _clientes = [...empiezaCon, ...contiene];
    return _clientes;
  }

  Future<List<Cliente>> obtenerClientesConDeuda() async {
    try {
      _clientesConDeuda = await _clienteService.obtenerClientesConDeuda();
      notifyListeners();
    } catch (e) {
      debugPrint('Error: $e');
      // Relanzar la excepción para que la UI la pueda manejar
      rethrow;
    }
    return _clientesConDeuda;
  }

  Future<Map<String, dynamic>> obtenerClientesConDeudaPaginados(int page, int pageSize) async {
    try {
      return await _clienteService.obtenerClientesConDeudaPaginados(page, pageSize);
    } catch (e) {
      debugPrint('Error al obtener clientes con deuda paginados: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleDeuda(int clienteId) async {
    try {
      return await _clienteService.obtenerDetalleDeuda(clienteId);
    } catch (e) {
      debugPrint('Error al obtener detalle de deuda: $e');
      rethrow;
    }
  }
}
