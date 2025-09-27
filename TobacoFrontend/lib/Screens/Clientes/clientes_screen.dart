import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';
import 'package:tobaco/Screens/Clientes/wizardNuevoCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/wizardEditarCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Utils/loading_utils.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ClienteService _clienteService = ClienteService();
  final TextEditingController _searchController = TextEditingController();
  
  // Variables para infinite scroll
  List<Cliente> _clientes = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  String _searchQuery = '';
  
  // ScrollController para detectar cuando llegar al final
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarClientes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMasClientes();
    }
  }

  Future<void> _cargarClientes() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _clientes.clear();
      _hasMoreData = true;
    });

    try {
      final data = await _clienteService.obtenerClientesPaginados(_currentPage, _pageSize);
      setState(() {
        _clientes = List<Cliente>.from(data['clientes']);
        _hasMoreData = data['hasNextPage'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('Error al cargar los clientes: $e', level: 1000);
    }
  }

  Future<void> _cargarMasClientes() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _clienteService.obtenerClientesPaginados(_currentPage + 1, _pageSize);
      setState(() {
        _clientes.addAll(List<Cliente>.from(data['clientes']));
        _currentPage++;
        _hasMoreData = data['hasNextPage'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('Error al cargar más clientes: $e', level: 1000);
    }
  }

  Future<void> _buscarClientes() async {
    if (_searchQuery.trim().isEmpty) {
      _cargarClientes();
      return;
    }

    setState(() {
      _isLoading = true;
      _clientes.clear();
    });

    try {
      final clientes = await _clienteService.buscarClientes(_searchQuery);
      setState(() {
        _clientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      log('Error al buscar clientes: $e', level: 1000);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    
    // Debounce para evitar muchas llamadas
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value) {
        _buscarClientes();
      }
    });
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  Future<void> _actualizarClienteEnLista(Cliente clienteOriginal) async {
    try {
      // Obtener los datos actualizados del cliente desde la API
      final clienteActualizado = await _clienteService.obtenerClientePorId(clienteOriginal.id!);
      
      setState(() {
        // Buscar el cliente en la lista y actualizarlo
        final index = _clientes.indexWhere((c) => c.id == clienteOriginal.id);
        if (index != -1) {
          _clientes[index] = clienteActualizado;
        }
      });
    } catch (e) {
      log('Error al actualizar cliente en lista: $e', level: 1000);
      // Si falla, recargar toda la lista como fallback
      _cargarClientes();
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de que desea eliminar al cliente "${cliente.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        if (cliente.id != null) {
          await _clienteService.eliminarCliente(cliente.id!);
          _cargarClientes(); // Recargar la lista
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente eliminado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cliente: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar clientes localmente si hay búsqueda
    final clientesFiltrados = _searchQuery.isNotEmpty
        ? _clientes.where((cliente) =>
            cliente.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        : _clientes;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Clientes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryColor),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WizardNuevoClienteScreen(),
                  ),
                );
                if (result == true) {
                  _cargarClientes();
                }
              },
            ),
          )
        ],
      ),
      body: _isLoading && _clientes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando clientes...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header fijo
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con estadísticas
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.1),
                              AppTheme.secondaryColor.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.people,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Gestión de Clientes',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      Text(
                                        '${_clientes.length} clientes registrados',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Botón de crear cliente
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const WizardNuevoClienteScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _cargarClientes();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.person_add, size: 20),
                                label: const Text(
                                  'Crear Nuevo Cliente',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Barra de búsqueda mejorada
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              selectionColor: AppTheme.primaryColor.withOpacity(0.3),
                              selectionHandleColor: AppTheme.primaryColor,
                              cursorColor: AppTheme.primaryColor,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            cursorColor: AppTheme.primaryColor,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Buscar clientes...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey.shade400,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Lista scrolleable de clientes
                Expanded(
                  child: clientesFiltrados.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No se encontraron clientes'
                                    : 'No hay clientes registrados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Intenta con otros términos de búsqueda'
                                    : 'Crea tu primer cliente para comenzar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: clientesFiltrados.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == clientesFiltrados.length) {
                              // Indicador de carga al final
                              return _isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final cliente = clientesFiltrados.elementAt(index);
                            return _buildClienteCard(cliente);
                          },
                        ),
                ),
              ],
            ),
    );
  }


  Widget _buildClienteCard(Cliente cliente) {
    final tieneDeuda = cliente.deuda != null && 
        cliente.deuda!.isNotEmpty && 
        cliente.deuda != '0' && 
        double.tryParse(cliente.deuda!) != null && 
        double.parse(cliente.deuda!) > 0;
    final tieneDescuento = cliente.descuentoGlobal > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleClienteScreen(cliente: cliente),
              ),
            );
            if (result == true) {
              _actualizarClienteEnLista(cliente);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de estado del cliente
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: tieneDeuda 
                        ? Colors.red 
                        : tieneDescuento 
                            ? Colors.green 
                            : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),

                // Información del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cliente.direccion!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (cliente.telefono != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cliente.telefono!.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cliente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (tieneDeuda) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'Con Deuda',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (tieneDescuento) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                '${cliente.descuentoGlobal.toStringAsFixed(1)}% desc.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WizardEditarClienteScreen(cliente: cliente),
                            ),
                          );
                          if (result == true) {
                            _actualizarClienteEnLista(cliente);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _eliminarCliente(cliente),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}