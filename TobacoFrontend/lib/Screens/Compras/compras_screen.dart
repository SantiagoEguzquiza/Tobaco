// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Compra.dart';
import 'package:tobaco/Screens/Compras/detalle_compra_screen.dart';
import 'package:tobaco/Screens/Compras/nueva_compra_screen.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Services/Compras_Service/compras_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  _ComprasScreenState createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final comprasProvider = context.read<ComprasProvider>();
      await comprasProvider.cargarCompras();
      if (!mounted) return;
      if (comprasProvider.isConnectionError) {
        await AppDialogs.showServerErrorDialog(context: context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final permisosProvider = context.watch<PermisosProvider>();
    if (!permisosProvider.canViewCompras) {
      return Scaffold(
        appBar: AppBar(centerTitle: true, title: const Text('Compras', style: AppTheme.appBarTitleStyle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No tienes permiso para ver este módulo',
                style: TextStyle(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }
    final provider = context.watch<ComprasProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Compras', style: AppTheme.appBarTitleStyle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              HeaderSimple(
                leadingIcon: Icons.shopping_cart,
                title: 'Compras de mercadería',
                subtitle: '${provider.compras.length} compra${provider.compras.length != 1 ? 's' : ''} registrada${provider.compras.length != 1 ? 's' : ''}',
              ),
              const SizedBox(height: 16),
              Consumer<PermisosProvider>(
                builder: (context, permisosProvider, child) {
                  if (!permisosProvider.canCreateCompras && !permisosProvider.isAdmin) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final comprasProvider = context.read<ComprasProvider>();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NuevaCompraScreen()),
                        );
                        if (!mounted) return;
                        if (result == true) {
                          await comprasProvider.cargarCompras();
                        }
                      },
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: AppTheme.ventasButtonIconSize(context),
                      ),
                      label: Text(
                        'Nueva compra',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: AppTheme.ventasButtonFontSize(context),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: AppTheme.ventasButtonPadding(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                        ),
                        elevation: 2,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildList(provider, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(ComprasProvider provider, bool isDark) {
    if (provider.isLoading && provider.compras.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }
    if ((provider.errorMessage != null || provider.isConnectionError) && provider.compras.isEmpty) {
      return Center(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  provider.isConnectionError ? Icons.cloud_off_rounded : Icons.error_outline,
                  size: 48,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  provider.isConnectionError
                      ? 'No hay compras registradas'
                      : provider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                if (provider.isConnectionError) ...[
                  const SizedBox(height: 8),
                  Text(
                    'No se pudieron cargar las compras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ],
                if (!provider.isConnectionError) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => provider.cargarCompras(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    if (provider.compras.isEmpty) {
      return Center(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No hay compras registradas',
                style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca "Nueva compra" para agregar una',
                style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => provider.cargarCompras(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: provider.compras.length,
        itemBuilder: (context, index) {
          final compra = provider.compras[index];
          return _buildCard(context, compra, isDark);
        },
      ),
    );
  }

  Future<void> _confirmDeleteCompra(Compra compra) async {
    final confirm = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar compra',
      message: '¿Eliminar esta compra?\n\nSe restaurará el stock de los productos involucrados (se restarán las cantidades que esta compra había sumado).\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
    );
    if (confirm != true) return;

    try {
      await context.read<ComprasProvider>().eliminarCompra(compra.id);
      if (!mounted) return;
      await context.read<ComprasProvider>().cargarCompras();
      if (!mounted) return;
      final categoriasProvider = context.read<CategoriasProvider>();
      await context.read<ProductoProvider>().recargarProductos(categoriasProvider);
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Compra eliminada correctamente'),
      );
    } catch (e) {
      if (!mounted) return;
      if (Apihandler.isConnectionError(e)) {
        await AppDialogs.showServerErrorDialog(context: context);
      } else {
        final msg = e.toString().replaceFirst('Exception: ', '');
        AppTheme.showSnackBar(context, AppTheme.errorSnackBar(msg));
      }
    }
  }

  Widget _buildCard(BuildContext context, Compra compra, bool isDark) {
    final proveedorNombre = compra.proveedor?.nombre ?? 'Proveedor #${compra.proveedorId}';
    final fechaStr = _formatFecha(compra.fecha);
    final isCompact = AppTheme.isCompactVentasButton(context);
    final canDeleteCompras = context.watch<PermisosProvider>().canDeleteCompras;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(compra.id),
        endActionPane: canDeleteCompras
            ? ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _confirmDeleteCompra(compra),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Eliminar',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppTheme.borderRadiusCards),
                bottomRight: Radius.circular(AppTheme.borderRadiusCards),
              ),
            ),
          ],
        )
            : null,
        child: Material(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleCompraScreen(compra: compra),
                ),
              );
              if (!mounted) return;
              await context.read<ComprasProvider>().cargarCompras();
            },
            child: Container(
              padding: EdgeInsets.all(isCompact ? 14 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
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
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryColor,
                    size: isCompact ? 24 : 28,
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proveedorNombre,
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
                        fechaStr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      if (compra.numeroComprobante != null && compra.numeroComprobante!.isNotEmpty)
                        Text(
                          'Comprobante: ${compra.numeroComprobante}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '\$${compra.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 14 : 16,
                        color: isDark ? Colors.white : Colors.black87,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
