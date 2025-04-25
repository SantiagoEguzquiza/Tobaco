import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';

class SeleccionarProductosScreen extends StatefulWidget {
  final List<ProductoSeleccionado> productosYaSeleccionados;

  const SeleccionarProductosScreen({
    super.key,
    required this.productosYaSeleccionados,
  });

  @override
  State<SeleccionarProductosScreen> createState() =>
      _SeleccionarProductosScreenState();
}

class _SeleccionarProductosScreenState
    extends State<SeleccionarProductosScreen> {
  List<Producto> todosLosProductos = []; // Obtener desde tu API
  final Map<int, int> cantidades = {};

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    final productos = await ProductoProvider().obtenerProductos();
    setState(() {
      todosLosProductos = productos;
      for (var ps in widget.productosYaSeleccionados) {
        cantidades[ps.producto.id!] = ps.cantidad;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Seleccionar', style: AppTheme.appBarTitleStyle),
      ),
      body: todosLosProductos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: todosLosProductos.length,
              itemBuilder: (context, index) {
                final producto = todosLosProductos[index];
                final cantidad = cantidades[producto.id] ?? 0;

                return ListTile(
                  title: Text(producto.nombre),
                  subtitle:
                      Text('Precio: \$${producto.precio.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (cantidad > 0) {
                            setState(() {
                              cantidades[producto.id!] = cantidad - 1;
                            });
                          }
                        },
                      ),
                      Text(cantidad.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            cantidades[producto.id!] = cantidad + 1;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            final seleccionados =
                cantidades.entries.where((e) => e.value > 0).map((e) {
              final producto =
                  todosLosProductos.firstWhere((p) => p.id == e.key);
              return ProductoSeleccionado(
                  producto: producto, cantidad: e.value);
            }).toList();

            Navigator.pop(context, seleccionados);
          },
          child: const Text("Confirmar selección"),
        ),
      ),
    );
  }
}
