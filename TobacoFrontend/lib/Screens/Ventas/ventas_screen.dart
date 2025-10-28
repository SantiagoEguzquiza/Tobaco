// ignore_for_file: library_private_types_in_public_api
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/io_client.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Screens/Ventas/detalleVentas_screen.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Services/Cache/ventas_cache_service.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Widgets/sync_status_widget.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  _VentasScreenState createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Ventas> ventas = [];
  late ScaffoldMessengerState scaffoldMessenger;
  bool _offlineMessageShown = false; // Para mostrar el mensaje solo la primera vez

  // Variables para infinite scroll
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  // ScrollController para detectar cuando llegar al final
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void initState() {
    super.initState();
    _loadVentas();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMasVentas();
    }
  }

  Future<void> _loadVentas() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
      _currentPage = 1;
      ventas.clear();
      _hasMoreData = false; // Para offline no hay paginación
    });

    try {
      print('🔄 VentasScreen: Iniciando carga de ventas...');
      
      final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
      
      print('🔄 VentasScreen: Obteniendo ventas...');
      final ventasList = await ventasProvider.obtenerVentas();
      
      if (!mounted) return;
      
      setState(() {
        ventas = ventasList;
        _hasMoreData = false; // Sin paginación en offline
        isLoading = false;
      });
      
      print('✅ VentasScreen: ${ventas.length} ventas cargadas exitosamente');
      
      // Verificar si estamos en modo offline
      // Si hay ventas y hay caché, verificar si el servidor está realmente disponible
      if (ventas.isNotEmpty && !_offlineMessageShown) {
        // Pequeño delay para asegurar que el provider terminó de cargar
        Future.delayed(Duration(milliseconds: 100), () async {
          try {
            final cacheService = VentasCacheService();
            final ventasCache = await cacheService.obtenerVentasDelCache();
            
            // Si hay caché disponible, verificar si el servidor está realmente disponible
            if (ventasCache.isNotEmpty && mounted && !_offlineMessageShown) {
              // Hacer una verificación rápida del servidor
              try {
                final testClient = IOClient(HttpClient()..badCertificateCallback = ((X509Certificate cert, String host, int port) => true));
                await testClient
                    .get(Uri.parse('${Apihandler.baseUrl}/Health'))
                    .timeout(Duration(milliseconds: 300));
                
                // Si el servidor responde, no estamos en modo offline
                // No mostrar mensaje
              } catch (e) {
                // Si falla la verificación del servidor, estamos en modo offline
                // Mostrar mensaje solo la primera vez
                if (mounted && !_offlineMessageShown) {
                  _offlineMessageShown = true;
                  AppTheme.showSnackBar(
                    context,
                    AppTheme.warningSnackBar('Modo Offline Activado'),
                  );
                }
              }
            }
          } catch (e) {
            // Ignorar error
          }
        });
      }

    } catch (e, stackTrace) {
      if (!mounted) return;
      
      print('❌ VentasScreen: Error al cargar las ventas: $e');
      print('Stack trace: $stackTrace');
      
      // Verificar si hay datos del caché disponibles
      if (Apihandler.isConnectionError(e)) {
        try {
          // Intentar obtener del caché directamente
          final cacheService = VentasCacheService();
          final ventasCache = await cacheService.obtenerVentasDelCache();
          
          if (ventasCache.isNotEmpty) {
            // Hay datos en caché, cargarlos
            setState(() {
              ventas = ventasCache;
              _hasMoreData = false;
              isLoading = false;
            });
            
            // Mostrar mensaje de modo offline solo la primera vez
            if (!_offlineMessageShown) {
              _offlineMessageShown = true;
              AppTheme.showSnackBar(
                context,
                AppTheme.warningSnackBar('Modo Offline Activado'),
              );
            }
            return;
          }
        } catch (cacheError) {
          // Si falla el caché, continuar con el error normal
        }
      }
      
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar ventas: $e';
      });
      
      // Mostrar error apropiado
      if (Apihandler.isConnectionError(e)) {
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar('Sin conexión. Verifica tu conexión a internet.'),
        );
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al cargar ventas: ${e.toString().replaceFirst('Exception: ', '')}'),
        );
      }
    }
  }

  Future<void> _cargarMasVentas() async {
    // En modo offline no hay paginación, todas las ventas se cargan de una vez
    if (_isLoadingMore || !_hasMoreData || !mounted) return;
    
    print('📋 VentasScreen: Paginación no disponible en modo offline');
    
    // Por ahora, deshabilitamos la paginación ya que obtenerVentas() 
    // trae todas las ventas offline de una vez
    // En el futuro se puede implementar paginación con SQLite si es necesario
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ventas', style: AppTheme.appBarTitleStyle),
        actions: [
          // Badge de sincronización en el AppBar
          FutureBuilder<int>(
            future: Provider.of<VentasProvider>(context, listen: false).contarVentasPendientes(),
            builder: (context, snapshot) {
              if (snapshot.data != null && snapshot.data! > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Badge(
                      label: Text('${snapshot.data}'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.cloud_upload),
                    ),
                    tooltip: '${snapshot.data} ventas pendientes',
                    onPressed: () async {
                      final provider = Provider.of<VentasProvider>(context, listen: false);
                      final result = await provider.sincronizarAhora();
                      
                      if (context.mounted) {
                        // Usar snackbar personalizado de AppTheme
                        if (result['success']) {
                          AppTheme.showSnackBar(
                            context,
                            AppTheme.successSnackBar(result['message']),
                          );
                        } else {
                          AppTheme.showSnackBar(
                            context,
                            AppTheme.warningSnackBar(result['message']),
                          );
                        }
                        _loadVentas();
                      }
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header principal con información y estadísticas
              _buildHeaderSection(),
              const SizedBox(height: 20),

              // Lista de ventas
              Expanded(
                child: _buildVentasList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header principal con información y estadísticas
  Widget _buildHeaderSection() {
    final TextEditingController _searchController = TextEditingController(text: searchQuery);
    
    return Column(
      children: [
        HeaderConBuscador(
          leadingIcon: Icons.storefront,
          title: 'Gestión de Ventas',
          subtitle: '${ventas.length} venta${ventas.length != 1 ? 's' : ''} registrada${ventas.length != 1 ? 's' : ''}',
          controller: _searchController,
          hintText: 'Buscar por cliente, fecha o total...',
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          onClear: () {
            setState(() {
              searchQuery = '';
            });
            _searchController.clear();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Botón nueva venta mejorado
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NuevaVentaScreen(),
                ),
              );
              _loadVentas();
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
            icon: const Icon(Icons.add_shopping_cart, size: 20),
            label: const Text(
              'Nueva Venta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // Sección de búsqueda mejorada
  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
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
      child: TextField(
        cursorColor: AppTheme.primaryColor,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar por cliente, fecha o total...',
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade400,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade400,
                  ),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
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
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  // Lista de ventas con diseño moderno
  Widget _buildVentasList() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    final filteredVentas = ventas.where((venta) {
      final clienteNombre = venta.cliente.nombre.toLowerCase();
      final fecha = '${venta.fecha.day}/${venta.fecha.month}';
      final total = venta.total.toString();
      return clienteNombre.contains(searchQuery) ||
          fecha.contains(searchQuery) ||
          total.contains(searchQuery);
    }).toList();

    if (filteredVentas.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredVentas.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredVentas.length) {
          return _buildLoadingIndicator();
        }
        final venta = filteredVentas[index];
        return _buildVentaCard(venta, index);
      },
    );
  }

  // Card individual de venta
  Widget _buildVentaCard(Ventas venta, int index) {
    // Para ventas offline, usar el hash del cliente+fecha como key
    final key = venta.id != null 
        ? Key(venta.id.toString())
        : Key('offline_${venta.clienteId}_${venta.fecha.millisecondsSinceEpoch}');
    
    return Slidable(
      key: key,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _confirmDeleteVenta(venta),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Eliminar',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: Container(
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
                  builder: (context) => DetalleVentaScreen(venta: venta),
                ),
              );
              // Refresh the list if venta was deleted or updated
              if (result == true || result == 'updated') {
                _loadVentas();
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
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información de la venta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venta.cliente.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppTheme.textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${venta.fecha.day}/${venta.fecha.month}/${venta.fecha.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${venta.ventasProductos.length} producto${venta.ventasProductos.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
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
                              _formatearPrecioTexto(venta.total),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildEstadoEntregaBadge(venta.estadoEntrega),
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
      ),
    );
  }

  // Estado de carga
  Widget _buildLoadingState() {
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando ventas...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Estado de error
  Widget _buildErrorState() {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar ventas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Error desconocido',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadVentas,
              style: AppTheme.elevatedButtonStyle(AppTheme.primaryColor),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Estado vacío
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty ? 'No se encontraron ventas' : 'No hay ventas registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty 
                  ? 'Intenta con otro término de búsqueda'
                  : 'Comienza creando tu primera venta',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Función para formatear precios
  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  }

  // Widget para formatear precios con decimales más pequeños y grises
  String _formatearPrecioTexto(double precio) {
    final precioStr = precio.toStringAsFixed(2);
    final partes = precioStr.split('.');
    final parteEntera = partes[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    final parteDecimal = partes[1];
    return '\$$parteEntera,$parteDecimal';
  }

  Widget _formatearPrecioConDecimales(double precio, {Color? color}) {
    final precioStr = precio.toStringAsFixed(2);
    final partes = precioStr.split('.');
    final parteEntera = partes[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    final parteDecimal = partes[1];
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$$parteEntera',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : (color ?? AppTheme.primaryColor),
            ),
          ),
          TextSpan(
            text: ',$parteDecimal',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // Función para confirmar eliminación de venta
  void _confirmDeleteVenta(Ventas venta) async {
    final confirm = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Venta',
      message: '¿Está seguro de que desea eliminar esta venta? Esta acción no se puede deshacer.',
    );

    if (confirm == true) {
      try {
        final ventasProvider = VentasProvider();
        await ventasProvider.eliminarVenta(venta.id ?? 0);

        if (!mounted) return;

        setState(() {
          ventas.remove(venta);
        });

        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Venta eliminada correctamente'),
        );
      } catch (e) {
        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al eliminar venta: $e'),
        );
      }
    }
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

  // Badge del estado de entrega
  Widget _buildEstadoEntregaBadge(EstadoEntrega estado) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (estado) {
      case EstadoEntrega.entregada:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case EstadoEntrega.parcial:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.access_time;
        break;
      case EstadoEntrega.noEntregada:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.local_shipping;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            estado.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
