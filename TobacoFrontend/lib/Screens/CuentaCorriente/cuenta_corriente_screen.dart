import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
import 'package:tobaco/Screens/CuentaCorriente/cuenta_corriente_detalle_screen.dart';
import 'dart:developer';

class CuentaCorrienteScreen extends StatefulWidget {
  const CuentaCorrienteScreen({super.key});

  @override
  _CuentaCorrienteScreenState createState() => _CuentaCorrienteScreenState();
}

class _CuentaCorrienteScreenState extends State<CuentaCorrienteScreen> {
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

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();

  double _headerVisibility = 1.0;
  double _lastScrollOffset = 0.0;
  double _maxHeaderHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });
    _loadClientes();
  }

  void _measureHeader() {
    final ctx = _headerKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        _maxHeaderHeight = box.size.height;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2);
  }

  double _parsearDeuda(String? deuda) {
    if (deuda == null || deuda.isEmpty) return 0.0;
    
    // El backend envía formatos como "1000,000", "2500,250", etc.
    // Vamos a tratar TODOS los casos como si la coma fuera decimal
    // y solo convertir a formato estándar con 2 decimales
    
    if (deuda.contains(',')) {
      List<String> partes = deuda.split(',');
      
      if (partes.length == 2) {
        String parteEntera = partes[0];
        String parteDecimal = partes[1];
        
        // Siempre convertir la coma a punto decimal
        // Si tiene más de 2 dígitos, tomar solo los primeros 2
        String decimalesFinales;
        if (parteDecimal.length >= 2) {
          decimalesFinales = parteDecimal.substring(0, 2);
        } else {
          // Si tiene menos de 2, rellenar con ceros
          decimalesFinales = parteDecimal.padRight(2, '0');
        }
        
        String numeroCorregido = '$parteEntera.$decimalesFinales';
        return double.tryParse(numeroCorregido) ?? 0.0;
      }
    }
    
    // Para otros formatos, usar la lógica normal
    String deudaLimpia = deuda.replaceAll(',', '');
    return double.tryParse(deudaLimpia) ?? 0.0;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;
    _lastScrollOffset = currentOffset;

    if (currentOffset >= _scrollController.position.maxScrollExtent - 200) {
      _cargarMasClientes();
    }

    if (_maxHeaderHeight <= 0 || delta.abs() > 200) return;
    double newVisibility;
    if (currentOffset <= 0) {
      newVisibility = 1.0;
    } else {
      newVisibility =
          (_headerVisibility - delta * 0.5 / _maxHeaderHeight).clamp(0.0, 1.0);
    }
    if ((newVisibility - _headerVisibility).abs() > 0.001) {
      setState(() {
        _headerVisibility = newVisibility;
      });
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
      
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        setState(() => isLoading = false);
        return;
      }
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
          message: 'Error al cargar clientes con cuenta corriente',
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
      
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
        return;
      }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });

    final filteredClientes = clientes.where((cliente) {
      final matchesSearchQuery = cliente.nombre
          .toLowerCase()
          .contains(_searchText.toLowerCase());
      return matchesSearchQuery;
    }).toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null,
        scrolledUnderElevation: 0,
        title: const Text(
          'Cuenta Corriente',
          style: AppTheme.appBarTitleStyle,
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: isLoading
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
                      'Cargando cuenta corriente...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).size.height < 680 ? 12 : 16,
                  16,
                  0,
                ),
                child: Column(
                  children: [
                    ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _headerVisibility,
                        child: Opacity(
                          opacity: _headerVisibility,
                          child: Column(
                            key: _headerKey,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HeaderConBuscador(
                                leadingIcon: Icons.account_balance_wallet,
                                title: 'Cuenta Corriente',
                                subtitle: '${clientes.length} cliente${clientes.length != 1 ? 's' : ''} con cuenta corriente',
                                controller: _searchController,
                                hintText: 'Buscar clientes...',
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
                              SizedBox(height: MediaQuery.of(context).size.height < 680 ? 10 : 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredClientes.isEmpty && !isLoading
                          ? SizedBox.expand(child: _buildEmptyState())
                          : _buildClientesList(filteredClientes),
                    ),
                  ],
                ),
              ),
            ),
        ),
    );
  }



  // Estado vacío: igual que pantalla Clientes (fondo gris oscuro + icono + dos líneas cortas)
  Widget _buildEmptyState() {
    return Container(
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
      child: Center(
        child: Padding(
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
                _searchText.isEmpty
                    ? 'No hay clientes con cuenta corriente'
                    : 'No se encontraron clientes',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchText.isEmpty
                    ? 'Habilita la cuenta corriente en un cliente para que aparezca aquí'
                    : 'Intenta con otro término de búsqueda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Lista de clientes
  Widget _buildClientesList(List<Cliente> filteredClientes) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadClientes,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: filteredClientes.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredClientes.length) {
            return _buildLoadingIndicator();
          }
          final cliente = filteredClientes[index];
          return _buildClienteCard(cliente, index);
        },
      ),
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
                builder: (context) => CuentaCorrienteDetalleScreen(cliente: cliente),
              ),
            );
            
            // Si regresamos con true, significa que se actualizó el saldo y debemos refrescar
            if (result == true) {
              _loadClientes();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador lateral
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _parsearDeuda(cliente.deuda) > 0 ? Colors.red : Colors.green,
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
                            Icons.attach_money,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _parsearDeuda(cliente.deuda) > 0
                                ? 'Deuda: \$ ${_formatearPrecio(_parsearDeuda(cliente.deuda))}'
                                : 'Sin deuda',
                            style: TextStyle(
                              fontSize: 14,
                              color: _parsearDeuda(cliente.deuda) > 0
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600)
                                  : Colors.green.shade600,
                              fontWeight: _parsearDeuda(cliente.deuda) > 0 ? FontWeight.normal : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),                                                               
                    ],
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
