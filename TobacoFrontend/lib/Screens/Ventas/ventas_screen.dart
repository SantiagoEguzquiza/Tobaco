import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Screens/Ventas/detalleVentas_screen.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  _VentasScreenState createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<_SincronizarButtonState> _syncButtonKey =
      GlobalKey<_SincronizarButtonState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Defer to after first frame to avoid setState/markNeedsBuild during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Mostrar loading de entrada y no la lista anterior (evita "listado → carga → listado de nuevo")
      context.read<VentasProvider>().prepararParaCargaInicial();
      _inicializarVentas();
    });
  }

  Future<void> _inicializarVentas() async {
    // No borrar ventas pendientes al abrir: se preservan para que el usuario
    // pueda sincronizar después (p. ej. si el servidor falló al guardar).
    if (!mounted) return;
    await context.read<VentasProvider>().cargarVentas(usarTimeoutNormal: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<VentasProvider>().cargarMasVentas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VentasProvider>();

    if (_searchController.text != provider.searchQuery) {
      _searchController.text = provider.searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Ventas', style: AppTheme.appBarTitleStyle),
        actions: [
          _SincronizarButton(
            key: _syncButtonKey,
            isSincronizando: provider.isSincronizando,
            onSincronizar: () async {
              final result =
                  await context.read<VentasProvider>().sincronizarAhora();
              if (!mounted) return;
              _manejarResultadoSincronizacion(context, result);
              // Asegurar que el contador se actualice.
              Future.delayed(const Duration(milliseconds: 300), () {
                _syncButtonKey.currentState?.recargarPendientes();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (provider.isOffline) ...[
                _buildOfflineBanner(),
                const SizedBox(height: 12),
              ],
              _buildHeaderSection(provider),
              const SizedBox(height: 20),
              Expanded(child: _buildVentasList(provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(VentasProvider provider) {
    return Column(
      children: [
        HeaderConBuscador(
          leadingIcon: Icons.storefront,
          title: 'Gestión de Ventas',
          subtitle:
              '${provider.ventas.length} venta${provider.ventas.length != 1 ? 's' : ''} registrada${provider.ventas.length != 1 ? 's' : ''}',
          controller: _searchController,
          hintText: 'Buscar por cliente, fecha o total...',
          onChanged: (value) =>
              context.read<VentasProvider>().actualizarBusqueda(value),
          onClear: () {
            _searchController.clear();
            context.read<VentasProvider>().actualizarBusqueda('');
          },
        ),
        const SizedBox(height: 16),
        // Botón Nueva Venta - Solo mostrar si tiene permiso
        Consumer<PermisosProvider>(
          builder: (context, permisosProvider, child) {
            if (permisosProvider.canCreateVentas || permisosProvider.isAdmin) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NuevaVentaScreen(),
                      ),
                    );
                    if (!mounted) return;
                    if (result != null) {
                      await context.read<VentasProvider>().cargarVentas();
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _syncButtonKey.currentState?.recargarPendientes();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 20),
                  label: const Text(
                    'Nueva Venta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 216, 101),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.black87),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modo offline',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentasList(VentasProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.errorMessage != null && provider.ventas.isEmpty) {
      return _buildErrorState(provider.errorMessage!);
    }

    final filteredVentas = provider.ventasFiltradas;

    if (filteredVentas.isEmpty) {
      return _buildEmptyState(provider.searchQuery.isNotEmpty);
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        await context.read<VentasProvider>().cargarVentas();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredVentas.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredVentas.length) {
            return _buildLoadingIndicator();
          }
          final venta = filteredVentas[index];
          return _buildVentaCard(venta, provider);
        },
      ),
    );
  }

  // Card individual de venta
  Widget _buildVentaCard(Ventas venta, VentasProvider provider) {
    final key = venta.id != null
        ? Key(venta.id.toString())
        : Key(
            'offline_${venta.clienteId}_${venta.fecha.millisecondsSinceEpoch}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Consumer<PermisosProvider>(
        builder: (context, permisosProvider, child) {
          final canDelete = permisosProvider.canDeleteVentas || permisosProvider.isAdmin;
          
          return Slidable(
            key: key,
            endActionPane: canDelete
                ? ActionPane(
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
                  )
                : null,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
                if (result == true || result == 'updated') {
                  if (!mounted) return;
                  await context.read<VentasProvider>().cargarVentas();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _syncButtonKey.currentState?.recargarPendientes();
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: provider.esVentaPendiente(venta) 
                            ? Colors.orange 
                            : Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venta.cliente.nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness == Brightness.dark
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
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${venta.fecha.day}/${venta.fecha.month}/${venta.fecha.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
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
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatearPrecioTexto(venta.total),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildEstadoEntregaBadge(venta.estadoEntrega),
                              // Badge de venta pendiente
                              if (provider.esVentaPendiente(venta)) ...[
                                const SizedBox(width: 8),
                                _buildPendienteBadge(),
                              ],
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
        },
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
  Widget _buildErrorState(String message) {
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
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<VentasProvider>().cargarVentas(),
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
  Widget _buildEmptyState(bool hasSearchQuery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark
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
                color: isDark
                    ? Colors.grey.shade800
                    : AppTheme.secondaryColor,
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
              hasSearchQuery
                  ? 'No se encontraron ventas'
                  : 'No hay ventas registradas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchQuery
                  ? 'Intenta con otro término de búsqueda'
                  : 'Comienza creando tu primera venta',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  // Función para confirmar eliminación de venta
  void _confirmDeleteVenta(Ventas venta) async {
    final confirm = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Venta',
      message:
          '¿Está seguro de que desea eliminar esta venta? Esta acción no se puede deshacer.',
    );

    if (confirm == true) {
      try {
        await context.read<VentasProvider>().eliminarVentaDeLista(venta);
        if (!mounted) return;
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

  void _manejarResultadoSincronizacion(
      BuildContext context, Map<String, dynamic> result) {
    final sincronizadas = (result['sincronizadas'] is int)
        ? result['sincronizadas'] as int
        : int.tryParse('${result['sincronizadas']}') ?? 0;
    final fallidas = (result['fallidas'] is int)
        ? result['fallidas'] as int
        : int.tryParse('${result['fallidas']}') ?? 0;
    final success = result['success'] == true;
    final message = (result['message'] ?? '').toString();

    if (success) {
      if (sincronizadas > 0 && fallidas == 0) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar(
            sincronizadas == 1
                ? '1 venta sincronizada correctamente'
                : '$sincronizadas ventas sincronizadas correctamente',
          ),
        );
      } else if (sincronizadas > 0 && fallidas > 0) {
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar(
            '$sincronizadas venta(s) sincronizada(s). $fallidas fallaron. Los datos siguen guardados localmente.',
          ),
        );
      } else if (sincronizadas == 0 && fallidas == 0) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('No hay ventas pendientes de sincronizar'),
        );
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar(message.isNotEmpty && message.contains('siguen guardados')
              ? message
              : 'Sincronización completada con advertencias. Los datos siguen guardados localmente.'),
        );
      }
    } else {
      // Verificar si fue por falta de conexión
      final noConnection = result['noConnection'] == true || 
          message.toLowerCase().contains('sin conexión') ||
          message.toLowerCase().contains('no hay conexión') ||
          message.toLowerCase().contains('se perdió la conexión');
      
      if (noConnection) {
        // Mensaje específico para falta de conexión
        AppTheme.showSnackBar(
          context,
          AppTheme.warningSnackBar(
            'Sin conexión. No se puede sincronizar en este momento. Los datos siguen guardados localmente.',
          ),
        );
      } else if (fallidas > 0) {
        // Si hay fallidas, asegurar que el mensaje indique que los datos están guardados
        final mensajeFinal = message.isNotEmpty && message.contains('siguen guardados')
            ? message
            : sincronizadas > 0
                ? '$sincronizadas venta(s) sincronizada(s). $fallidas fallaron. Los datos siguen guardados localmente.'
                : 'Error al sincronizar. Los datos siguen guardados localmente. Puedes reintentar más tarde.';
        
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(mensajeFinal),
        );
      } else {
        // Error general - siempre indicar que los datos están guardados
        final mensajeFinal = message.isNotEmpty && message.contains('siguen guardados')
            ? message
            : 'Error al sincronizar. Los datos siguen guardados localmente. Puedes reintentar más tarde.';
        
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(mensajeFinal),
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

  // Badge de venta pendiente
  Widget _buildPendienteBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(
            'Pendiente',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
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

/// Widget para el botón de sincronización que se actualiza automáticamente
class _SincronizarButton extends StatefulWidget {
  final bool isSincronizando;
  final VoidCallback onSincronizar;

  const _SincronizarButton({
    super.key,
    required this.isSincronizando,
    required this.onSincronizar,
  });

  @override
  State<_SincronizarButton> createState() => _SincronizarButtonState();
}

class _SincronizarButtonState extends State<_SincronizarButton> {
  int? _pendientes;
  bool _isLoading = false;
  bool _tieneConexion = true;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
    _verificarConexion();
  }

  Future<void> _verificarConexion() async {
    try {
      final connectivityService = ConnectivityService();
      final isConnected = await connectivityService.checkFullConnectivity();
      if (mounted) {
        setState(() {
          _tieneConexion = isConnected;
        });
      }
    } catch (e) {
      // Si falla la verificación, asumir que no hay conexión por seguridad
      if (mounted) {
        setState(() {
          _tieneConexion = false;
        });
      }
    }
  }

  // Método público para recargar pendientes (llamado desde el padre)
  void recargarPendientes() {
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    if (_isLoading) return; // Evitar cargas simultáneas

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<VentasProvider>(context, listen: false);
      final count = await provider.contarVentasPendientes();

      if (mounted) {
        setState(() {
          _pendientes = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Si ya teníamos un valor, mantenerlo; si no, usar 0 para no mostrar icono por error
          _pendientes ??= 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(_SincronizarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si terminó de sincronizar (exitosa o fallida), SIEMPRE recargar el contador y verificar conexión
    if (oldWidget.isSincronizando && !widget.isSincronizando) {
      // Esperar un momento para asegurar que la BD se actualizó
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _cargarPendientes();
          _verificarConexion();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar pendientes cuando cambian las dependencias (por ejemplo, al volver a la pantalla)
    // Solo si no está cargando actualmente
    if (!_isLoading && _pendientes == null) {
      _cargarPendientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar el botón solo cuando hay ventas pendientes (count conocido y > 0)
    // o cuando está sincronizando. No mostrar icono mientras se obtiene el conteo,
    // así no aparece nada al entrar a Ventas si no hay pendientes.
    if (_pendientes != null && _pendientes! > 0) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
          icon: widget.isSincronizando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Badge(
                  label: Text('$_pendientes'),
                  backgroundColor: _tieneConexion ? Colors.red : Colors.grey,
                  child: Icon(
                    Icons.cloud_upload,
                    color: _tieneConexion ? null : Colors.grey,
                  ),
                ),
          tooltip: widget.isSincronizando
              ? 'Sincronizando...'
              : !_tieneConexion
                  ? 'Sin conexión. No se puede sincronizar en este momento.'
                  : '$_pendientes ventas pendientes',
          onPressed: (widget.isSincronizando || !_tieneConexion)
              ? () {
                  if (!_tieneConexion) {
                    AppTheme.showSnackBar(
                      context,
                      AppTheme.warningSnackBar(
                        'Sin conexión. No se puede sincronizar en este momento. Los datos siguen guardados localmente.',
                      ),
                    );
                  }
                }
              : widget.onSincronizar,
        ),
      );
    }

    // Mientras sincroniza (y aún no tenemos conteo o es 0), mostrar solo el spinner sin badge
    if (widget.isSincronizando) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
          icon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          tooltip: 'Sincronizando...',
          onPressed: null,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
