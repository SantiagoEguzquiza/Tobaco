import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_service.dart';
import 'package:tobaco/Screens/Clientes/wizardNuevoCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/wizardEditarCliente_screen.dart';
import 'package:tobaco/Screens/Clientes/detalleCliente_screen.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Utils/loading_utils.dart';
import 'package:tobaco/Helpers/api_handler.dart';

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
    if (_isLoading || !mounted) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _clientes.clear();
      _hasMoreData = true;
    });

    try {
      final data = await _clienteService.obtenerClientesPaginados(_currentPage, _pageSize);
      if (!mounted) return;
      
      setState(() {
        _clientes = List<Cliente>.from(data['clientes']);
        _hasMoreData = data['hasNextPage'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      log('Error al cargar los clientes: $e', level: 1000);
      
      if (Apihandler.isConnectionError(e)) {
        setState(() {
          _isLoading = false;
          // No establecer errorMessage para errores de conexión
        });
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          _isLoading = false;
        });
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar clientes',
        );
      }
    }
  }

  Future<void> _cargarMasClientes() async {
    if (_isLoading || !_hasMoreData || !mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _clienteService.obtenerClientesPaginados(_currentPage + 1, _pageSize);
      if (!mounted) return;
      
      setState(() {
        _clientes.addAll(List<Cliente>.from(data['clientes']));
        _currentPage++;
        _hasMoreData = data['hasNextPage'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      log('Error al cargar más clientes: $e', level: 1000);
      
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar más clientes',
        );
      }
    }
  }

  Future<void> _buscarClientes() async {
    if (_searchQuery.trim().isEmpty) {
      _cargarClientes();
      return;
    }

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _clientes.clear();
    });

    try {
      final clientes = await _clienteService.buscarClientes(_searchQuery);
      if (!mounted) return;
      
      setState(() {
        _clientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      log('Error al buscar clientes: $e', level: 1000);
      
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al buscar clientes',
        );
      }
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
      if (!mounted) return;
      
      setState(() {
        // Buscar el cliente en la lista y actualizarlo
        final index = _clientes.indexWhere((c) => c.id == clienteOriginal.id);
        if (index != -1) {
          _clientes[index] = clienteActualizado;
        }
      });
    } catch (e) {
      log('Error al actualizar cliente en lista: $e', level: 1000);
      
      if (mounted && Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      }
      // Si falla, recargar toda la lista como fallback
      if (mounted) {
        _cargarClientes();
      }
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final confirmacion = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Cliente',
      itemName: cliente.nombre,
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
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
        } else if (mounted) {
          await AppDialogs.showErrorDialog(
            context: context,
            message: 'Error al eliminar cliente: ${e.toString().replaceFirst('Exception: ', '')}',
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Clientes',
          style: AppTheme.appBarTitleStyle,
        ),
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
                // Header con buscador
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderConBuscador(
                        leadingIcon: Icons.people,
                        title: 'Gestión de Clientes',
                        subtitle: '${_clientes.length} clientes registrados',
                        controller: _searchController,
                        hintText: 'Buscar clientes...',
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cliente.direccion!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
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
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cliente.telefono!.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
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
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cliente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
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