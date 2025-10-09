import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'dart:developer';

class DeudasScreen extends StatefulWidget {
  const DeudasScreen({super.key});

  @override
  _DeudasScreenState createState() => _DeudasScreenState();
}

class _DeudasScreenState extends State<DeudasScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Cliente> clientes = [];
  final TextEditingController _searchController = TextEditingController();

  // Variables para infinite scroll
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  // ScrollController para detectar cuando llegar al final
  final ScrollController _scrollController = ScrollController();

   @override
  void initState() {
    super.initState();
    _loadClientes();
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



  Future<void> _loadClientes() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
      _currentPage = 1;
      clientes.clear();
      _hasMoreData = true;
    });

    try {
      final clienteProvider = ClienteProvider();
      final data = await clienteProvider.obtenerClientesConDeudaPaginados(_currentPage, _pageSize);

      if (!mounted) return;
      
      setState(() {
        clientes = List<Cliente>.from(data['clientes']);
        _hasMoreData = data['hasNextPage'];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      log('Error al cargar los clientes: $e', level: 1000);
      
      if (Apihandler.isConnectionError(e)) {
        setState(() {
          isLoading = false;
          // No establecer errorMessage para errores de conexión
        });
        await Apihandler.handleConnectionError(context, e);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar los clientes: $e';
        });
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar clientes con deuda',
        );
      }
    }
  }

  Future<void> _cargarMasClientes() async {
    if (_isLoadingMore || !_hasMoreData || !mounted) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final clienteProvider = ClienteProvider();
      final data = await clienteProvider.obtenerClientesConDeudaPaginados(_currentPage + 1, _pageSize);
      
      if (!mounted) return;
      
      setState(() {
        clientes.addAll(List<Cliente>.from(data['clientes']));
        _currentPage++;
        _hasMoreData = data['hasNextPage'];
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoadingMore = false;
      });
      log('Error al cargar más clientes: $e', level: 1000);
      
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar más clientes: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredClientes = clientes.where((cliente) {
      final matchesSearchQuery = cliente.nombre
          .toLowerCase()
          .contains(_searchText.toLowerCase());
      return matchesSearchQuery;
    }).toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: const Text(
          'Deudas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF), // Blanco puro
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando deudas...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con buscador
                  HeaderConBuscador(
                    leadingIcon: Icons.account_balance_wallet,
                    title: 'Gestión de Deudas',
                    subtitle: '${clientes.length} cliente${clientes.length != 1 ? 's' : ''} con deuda',
                    controller: _searchController,
                    hintText: 'Buscar clientes con deuda...',
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _searchText = '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Lista de clientes con deuda
                  if (filteredClientes.isEmpty && !isLoading)
                    _buildEmptyState()
                  else
                    _buildClientesList(filteredClientes),
                ],
              ),
            ),
    );
  }



  // Estado vacío
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchText.isEmpty
                ? 'No hay clientes con deuda'
                : 'No se encontraron clientes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchText.isEmpty
                ? 'Todos los clientes están al día con sus pagos'
                : 'Intenta con otro término de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Lista de clientes
  Widget _buildClientesList(List<Cliente> filteredClientes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clientes con Deuda',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredClientes.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredClientes.length) {
              return _buildLoadingIndicator();
            }
            final cliente = filteredClientes[index];
            return _buildClienteCard(cliente, index);
          },
        ),
      ],
    );
  }

  // Tarjeta de cliente
  Widget _buildClienteCard(Cliente cliente, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // TODO: Navegar a detalles del cliente o cobrar deuda
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deuda: \$${cliente.deuda ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (cliente.telefono != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Tel: ${cliente.telefono}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.withOpacity(0.2)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Deuda',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red.shade400
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }
}
