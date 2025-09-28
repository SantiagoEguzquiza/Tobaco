import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Productos/editarProducto_screen.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema

class DetalleProductoScreen extends StatelessWidget {
  final Producto producto;

  const DetalleProductoScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(producto.nombre, style: AppTheme.appBarTitleStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categoría:', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: AppTheme.sectionBoxDecoration,
              child: Text(
                producto.categoriaNombre ?? 'No disponible',
                style: AppTheme.sectionContentStyle,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Precio:', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: AppTheme.sectionBoxDecoration,
              child: Text(
                '\$${producto.precio.toStringAsFixed(2)}', // Formato de precio
                style: AppTheme.sectionContentStyle,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cantidad:', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: AppTheme.sectionBoxDecoration,
              child: Text(
                producto.cantidad?.toString() ?? 'No disponible', // Validación de cantidad
                style: AppTheme.sectionContentStyle,
              ),
            ),
            const SizedBox(height: 20),
            const Text('¿Se puede vender medio?:', style: AppTheme.sectionTitleStyle),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: AppTheme.sectionBoxDecoration,
              child: Text(
                producto.half ? 'Sí' : 'No', // Muestra si se puede vender medio
                style: AppTheme.sectionContentStyle,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar eliminación'),
                              content: const Text(
                                  '¿Está seguro de que desea eliminar este producto?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          if (producto.id != null) {
                            try {
                              // Intentar eliminación física primero
                              await ProductoProvider().eliminarProducto(producto.id!);
                              
                              // Si llegamos aquí, la eliminación fue exitosa (sin ventas vinculadas)
                              AppTheme.showSnackBar(
                                context,
                                AppTheme.successSnackBar('Producto eliminado con éxito'),
                              );
                              Navigator.of(context).pop(true); // Return true to indicate deletion
                              
                            } catch (e) {
                              // Si es un error 409 (Conflict) - producto con ventas vinculadas
                              if (e.toString().contains('ventas vinculadas') || 
                                  e.toString().contains('Conflict')) {
                                _showDeactivateDialog(context, producto);
                              } else {
                                // Otros errores
                                AppTheme.showSnackBar(
                                  context,
                                  AppTheme.errorSnackBar(e.toString().replaceFirst('Exception: ', '')),
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
                      style: AppTheme.elevatedButtonStyle(
                        const Color.fromARGB(255, 255, 141, 141),
                      ),
                      child:
                          Image.asset('Assets/images/borrar.png', height: 30),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Navegar a la pantalla de edición
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditarProductoScreen(
                              producto: producto,
                            ),
                          ),
                        );
                      },
                      style: AppTheme.elevatedButtonStyle(
                        const Color.fromARGB(255, 251, 247, 135),
                      ),
                      child:
                          Image.asset('Assets/images/editar.png', height: 30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: AppTheme.outlinedButtonStyle,
                child: const Text(
                  'Volver',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
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
                'El producto "${producto.nombre}" no se puede eliminar porque tiene ventas vinculadas.',
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
                      'El producto se ocultará de los catálogos pero se mantendrá en las ventas existentes',
                      style: TextStyle(fontSize: 14),
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _deactivateProduct(context, producto);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Desactivar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deactivateProduct(BuildContext context, Producto producto) async {
    if (producto.id != null) {
      final errorMessage = await ProductoProvider()
          .desactivarProductoConMensaje(producto.id!);
      
      if (errorMessage == null) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Producto desactivado exitosamente. Ya no aparecerá en los catálogos.'),
        );
        Navigator.of(context).pop(true); // Return true to indicate deactivation
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(errorMessage),
        );
      }
    }
  }
}
