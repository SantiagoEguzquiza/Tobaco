import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
import 'package:tobaco/Screens/CuentaCorriente/cuenta_corriente_detalle_screen.dart';

class CuentaCorrienteScreen extends StatefulWidget {
  const CuentaCorrienteScreen({super.key});

  @override
  _CuentaCorrienteScreenState createState() => _CuentaCorrienteScreenState();
}

class _CuentaCorrienteScreenState extends State<CuentaCorrienteScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Cliente> clientes = [];
  final TextEditingController _searchController = TextEditingController();

  // Paginación / infinite scroll (modo normal)
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  // Modo búsqueda API
  String _searchText = '';
  bool _isSearchMode = false;
  bool _isSearchLoading = false;
  List<Cliente> _searchResults = [];
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
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

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchText = '';
        _isSearchMode = false;
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }
    setState(() {
      _searchText = value;
      _isSearchLoading = true;
      _isSearchMode = true;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _buscarEnBackend(value.trim());
    });
  }

  Future<void> _buscarEnBackend(String query) async {
    if (!mounted) return;
    try {
      final results = await ClienteProvider().buscarClientesConDeuda(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearchLoading = false);
      if (AuthService.isSessionExpiredException(e)) {
        await AuthService.logout();
      } else if (!Apihandler.isConnectionError(e)) {
        log('Error al buscar clientes: $e', level: 1000);
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _lastScrollOffset;
    _lastScrollOffset = currentOffset;

    if (!_isSearchMode && currentOffset >= _scrollController.position.maxScrollExtent - 200) {
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureHeader();
    });

    final displayedClientes = _isSearchMode ? _searchResults : clientes;
    final subtitle = _isSearchMode
        ? '${_searchResults.length} resultado${_searchResults.length != 1 ? 's' : ''}'
        : '${clientes.length} cliente${clientes.length != 1 ? 's' : ''} con cuenta corriente';

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
                      style: TextStyle(color: Colors.grey, fontSize: 16),
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
                                  subtitle: subtitle,
                                  controller: _searchController,
                                  hintText: 'Buscar clientes...',
                                  onChanged: _onSearchChanged,
                                  onClear: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height < 680 ? 10 : 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isSearchLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              )
                            : displayedClientes.isEmpty
                                ? SizedBox.expand(child: _buildEmptyState())
                                : _buildClientesList(displayedClientes),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

  // Tarjeta de cliente (mismo estilo que compras, ventas, productos y clientes)
  Widget _buildClienteCard(Cliente cliente, int index) {
    final deuda = _parsearDeuda(cliente.deuda);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = AppTheme.isCompactVentasButton(context);

    final Color estadoColor = deuda > 0
        ? Colors.red.shade600
        : deuda < 0
            ? Colors.green.shade600
            : (isDark ? Colors.grey.shade500 : Colors.grey.shade500);
    final IconData estadoIcon = deuda > 0
        ? Icons.trending_down
        : deuda < 0
            ? Icons.trending_up
            : Icons.account_balance_wallet_outlined;
    final String estadoLabel = deuda > 0
        ? 'Deuda pendiente'
        : deuda < 0
            ? 'Saldo a favor'
            : 'Sin deuda';
    final double montoAbsoluto = deuda.abs();
    final bool mostrarMonto = deuda != 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CuentaCorrienteDetalleScreen(cliente: cliente),
              ),
            );
            if (result == true) {
              _loadClientes();
            }
          },
          child: Container(
            padding: EdgeInsets.all(isCompact ? 14 : 16),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadiusCards),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    estadoIcon,
                    color: estadoColor,
                    size: isCompact ? 24 : 28,
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cliente.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 15 : 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      Text(
                        estadoLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 14,
                          color: estadoColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 10),
                Text(
                  mostrarMonto
                      ? '\$${_formatearPrecio(montoAbsoluto)}'
                      : '\$0,00',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: mostrarMonto
                        ? estadoColor
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ),
                SizedBox(width: isCompact ? 2 : 4),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: isCompact ? 20 : 24,
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
