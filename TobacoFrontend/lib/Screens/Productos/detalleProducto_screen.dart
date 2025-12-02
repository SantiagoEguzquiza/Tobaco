import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Productos/editarProducto_screen.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_service.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema
import 'package:tobaco/Theme/dialogs.dart'; // Importa los diálogos
import 'package:tobaco/Helpers/api_handler.dart';

class DetalleProductoScreen extends StatefulWidget {
  final Producto producto;

  const DetalleProductoScreen({super.key, required this.producto});

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  late Producto _producto;

  @override
  void initState() {
    super.initState();
    _producto = widget.producto;
  }

  Future<void> _actualizarProducto() async {
    if (_producto.id == null) return;
    
    try {
      // Primero intentar buscar en el provider
      final provider = Provider.of<ProductoProvider>(context, listen: false);
      final productoEnProvider = provider.productos.firstWhere(
        (p) => p.id == _producto.id,
        orElse: () => _producto,
      );
      
      // Si se encontró en el provider y es diferente, actualizar
      if (productoEnProvider.id == _producto.id && productoEnProvider != _producto) {
        setState(() {
          _producto = productoEnProvider;
        });
        return;
      }
      
      // Si no está en el provider, obtenerlo desde el servidor
      final productoService = ProductoService();
      final productoActualizado = await productoService.obtenerProductoPorId(_producto.id!);
      
      if (mounted) {
        setState(() {
          _producto = productoActualizado;
        });
      }
    } catch (e) {
      // Si falla, no hacer nada (el producto actual se mantiene)
      debugPrint('Error al actualizar producto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF66BB6A),
          surface: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F0F0F)
            : const Color(0xFFF8F9FA),
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            _producto.nombre,
            style: AppTheme.appBarTitleStyle,
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : const Color(0xFF4CAF50),
          iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.white,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con información principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF4CAF50),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _producto.nombre,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _producto.categoriaNombre ?? 'Sin categoría',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información detallada
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Producto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Precio
                    _buildInfoRow(
                      context,
                      'Precio',
                      '\$${_producto.precio.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                    const SizedBox(height: 20),
                    
                    // Stock
                    _buildInfoRow(
                      context,
                      'Stock disponible',
                      _producto.stock?.toString() ?? 'No disponible',
                      Icons.inventory,
                    ),
                    const SizedBox(height: 20),
                    
                    // Marca
                    if (_producto.marca != null && _producto.marca!.isNotEmpty)
                      _buildInfoRow(
                        context,
                        'Marca',
                        _producto.marca!,
                        Icons.branding_watermark,
                      ),
                    if (_producto.marca != null && _producto.marca!.isNotEmpty)
                      const SizedBox(height: 20),
                    
                    // Se puede vender medio
                    _buildInfoRow(
                      context,
                      '¿Se puede vender medio?',
                      _producto.half ? 'Sí' : 'No',
                      Icons.hourglass_empty,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Acciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Botones de acción - Ocultar según permisos
                    Consumer<PermisosProvider>(
                      builder: (context, permisosProvider, child) {
                        final canEdit = permisosProvider.canEditProductos || permisosProvider.isAdmin;
                        final canDelete = permisosProvider.canDeleteProductos || permisosProvider.isAdmin;
                        
                        // Si no tiene ningún permiso de acción, no mostrar nada
                        if (!canEdit && !canDelete) {
                          return const SizedBox.shrink();
                        }
                        
                        return Column(
                          children: [
                            // Botón Editar
                            if (canEdit)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditarProductoScreen(
                                          producto: _producto,
                                        ),
                                      ),
                                    );
                                    
                                    // Si se guardó exitosamente, actualizar el producto
                                    if (result == true) {
                                      _actualizarProducto();
                                    }
                                  },
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                                  label: const Text(
                                    'Editar Producto',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            
                            if (canEdit && canDelete)
                              const SizedBox(height: 12),
                            
                            // Botón Eliminar
                            if (canDelete)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final confirm = await AppDialogs.showDeleteConfirmationDialog(
                                      context: context,
                                      title: 'Eliminar Producto',
                                      itemName: _producto.nombre,
                                      confirmText: 'Eliminar',
                                      cancelText: 'Cancelar',
                                    );

                                    if (confirm == true) {
                                      if (_producto.id != null) {
                                        try {
                                          await ProductoProvider().eliminarProducto(_producto.id!);
                                          AppTheme.showSnackBar(
                                            context,
                                            AppTheme.successSnackBar('Producto eliminado con éxito'),
                                          );
                                          Navigator.of(context).pop(true);
                                        } catch (e) {
                                          if (e.toString().contains('ventas vinculadas') || 
                                              e.toString().contains('Conflict')) {
                                            _showDeactivateDialog(context, _producto);
                                          } else if (Apihandler.isConnectionError(e)) {
                                            await Apihandler.handleConnectionError(context, e);
                                          } else {
                                            await AppDialogs.showErrorDialog(
                                              context: context,
                                              message: 'Error al eliminar producto: ${e.toString().replaceFirst('Exception: ', '')}',
                                            );
                                          }
                                        }
                                      } else {
                                        AppTheme.showSnackBar(
                                          context,
                                          AppTheme.errorSnackBar('Error: ID del producto no válido'),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                                  label: const Text(
                                    'Eliminar Producto',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Botón Volver
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        label: Text(
                          'Volver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade600
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4CAF50),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeactivateDialog(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No se puede eliminar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El producto "${_producto.nombre}" no se puede eliminar porque tiene ventas vinculadas.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Desea desactivarlo en su lugar?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'El producto se marcará como inactivo pero se mantendrá en el historial de ventas.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deactivateProduct(context, producto);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Desactivar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deactivateProduct(BuildContext context, Producto producto) async {
    try {
      await ProductoProvider().eliminarProducto(producto.id!);
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('Producto desactivado con éxito'),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        await Apihandler.handleConnectionError(context, e);
      } else {
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al desactivar producto: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }
}