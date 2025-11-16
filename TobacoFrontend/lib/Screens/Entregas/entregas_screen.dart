import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Screens/Entregas/detalle_entregas_screen.dart';

class EntregasScreen extends StatefulWidget {
  const EntregasScreen({super.key});

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<EstadoEntrega> _estadoFilters = {
    EstadoEntrega.noEntregada,
    EstadoEntrega.parcial,
  };
  String _searchQuery = '';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarVentasPendientes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarVentasPendientes({bool usarTimeoutNormal = false}) async {
    final provider = context.read<VentasProvider>();
    try {
      await provider.cargarVentas(usarTimeoutNormal: usarTimeoutNormal);
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Entregas', style: AppTheme.appBarTitleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => _cargarVentasPendientes(usarTimeoutNormal: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<VentasProvider>(
          builder: (context, provider, _) {
            final ventasPendientes = _filtrarVentas(provider.ventas);

            if (_isInitializing && provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            }

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () => _cargarVentasPendientes(usarTimeoutNormal: true),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: ventasPendientes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeaderSection(
                      provider,
                      ventasPendientes.length,
                    );
                  }
                  final venta = ventasPendientes[index - 1];
                  return _buildVentaCard(venta);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(VentasProvider provider, int totalPendientes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderConBuscador(
          leadingIcon: Icons.local_shipping,
          title: 'Entregas pendientes',
          subtitle: totalPendientes == 0
              ? 'No hay entregas pendientes por el momento'
              : '$totalPendientes venta${totalPendientes == 1 ? '' : 's'} pendientes',
          controller: _searchController,
          hintText: 'Buscar por cliente o número de venta...',
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
          onClear: () {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildEstadoFilterChip(
              estado: EstadoEntrega.noEntregada,
              label: 'No entregada',
              color: Colors.red.shade100,
            ),
            _buildEstadoFilterChip(
              estado: EstadoEntrega.parcial,
              label: 'Parcial',
              color: Colors.orange.shade100,
            ),
          ],
        ),
        if (provider.isOffline) ...[
          const SizedBox(height: 16),
          _buildOfflineBanner(),
        ],
        if (provider.errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(provider.errorMessage!),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEstadoFilterChip({
    required EstadoEntrega estado,
    required String label,
    required Color color,
  }) {
    final selected = _estadoFilters.contains(estado);
    final baseColor = estado == EstadoEntrega.noEntregada
        ? Colors.red
        : Colors.orange;
    
    return FilterChip(
      label: Text(label),
      avatar: Icon(
        estado == EstadoEntrega.noEntregada
            ? Icons.local_shipping_outlined
            : Icons.access_time,
        size: 18,
        color: selected ? Colors.white : baseColor.shade700,
      ),
      selected: selected,
      backgroundColor: baseColor.withOpacity(0.2),
      selectedColor: baseColor.shade600,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : baseColor.shade700,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (value) {
        setState(() {
          if (value) {
            _estadoFilters.add(estado);
          } else {
            if (_estadoFilters.length > 1) {
              _estadoFilters.remove(estado);
            }
          }
        });
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Trabajando sin conexión. Los cambios se sincronizarán al recuperar internet.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCard(Ventas venta) {
    final ventaKey = _ventaKey(venta);
    final fechaFormateada = DateFormat('dd/MM/yyyy').format(venta.fecha);
    final totalFormateado = _formatearPrecioTexto(venta.total);
    final pendientes =
        venta.ventasProductos.where((producto) => !producto.entregado).length;
    final entregados = venta.ventasProductos.length - pendientes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey(ventaKey),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleEntregasScreen(venta: venta),
              ),
            );
            if (!mounted) return;
            if (result == true || result == 'updated') {
              await _cargarVentasPendientes(usarTimeoutNormal: true);
            } else {
              setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                      foregroundColor: AppTheme.primaryColor,
                      child: const Icon(Icons.receipt_long),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venta.cliente.nombre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                fechaFormateada,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.attach_money,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                totalFormateado,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Colors.grey.shade500, size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildEstadoEntregaBadge(venta.estadoEntrega),
                    const SizedBox(width: 8),
                    _buildResumenProductosBadge(
                      pendientes: pendientes,
                      entregados: entregados,
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

  List<Ventas> _filtrarVentas(List<Ventas> ventas) {
    final filtros = ventas.where((venta) {
      final estadoValido = _estadoFilters.contains(venta.estadoEntrega);
      if (!estadoValido) return false;

      final coincideBusqueda = _searchQuery.isEmpty
          ? true
          : venta.cliente.nombre.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (venta.id?.toString().contains(_searchQuery) ?? false);

      if (!coincideBusqueda) return false;

      return true;
    }).toList();

    filtros.sort((a, b) => b.fecha.compareTo(a.fecha));
    return filtros;
  }

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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenProductosBadge({
    required int pendientes,
    required int entregados,
  }) {
    final pendienteText =
        pendientes == 1 ? '1 pendiente' : '$pendientes pendientes';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        pendientes == 0
            ? 'Sin pendientes'
            : '$pendienteText · $entregados entregados',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  String _ventaKey(Ventas venta) {
    if (venta.id != null) return 'venta_${venta.id}';
    return 'offline_${venta.clienteId}_${venta.fecha.millisecondsSinceEpoch}';
  }

  String _formatearPrecioTexto(double precio) {
    final precioStr = precio.toStringAsFixed(2);
    final partes = precioStr.split('.');
    final parteEntera = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final parteDecimal = partes[1];
    return '\$$parteEntera,$parteDecimal';
  }
}
