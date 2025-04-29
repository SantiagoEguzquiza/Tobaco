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
                producto.categoria.nombre, // Muestra el nombre de la categoría
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
                          try {
                            if (producto.id != null) {
                              await ProductoProvider()
                                  .eliminarProducto(producto.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Producto eliminado con éxito'),
                                ),
                              );
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error: ID del producto no válido'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al eliminar: ${e.toString()}'),
                              ),
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
}
