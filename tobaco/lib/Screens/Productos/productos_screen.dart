// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Screens/Productos/nuevoProducto_screen.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'dart:developer';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  _ProductosScreenState createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  bool isLoading = true;
  String searchQuery = '';
  String? errorMessage;
  List<Producto> productos = [];

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

   Future<void> _loadProductos() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final productoProvider = ProductoProvider();
      final List<Producto> fetchedProductos =
          await productoProvider.obtenerProductos();

      setState(() {
        productos = fetchedProductos; 
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar los Productos: $e';
      });
      log('Error al cargar los Productos: $e', level: 1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProductos = productos
        .where((producto) =>
            producto.nombre.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Productos',
          style: TextStyle(fontSize: 32),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity, // Ancho completo
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NuevoProductoScreen(),
                    ),
                  );
                  _loadProductos();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  backgroundColor: const Color(0xFFAAEDAA), // Color de fondo
                  elevation: 5, // Altura de la sombra
                  shadowColor: Colors.black, // Color de la sombra
                ),
                child: const Text(
                  'Crear nuevo producto',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              cursorColor: Colors.black, // Cambia el color del cursor a negro
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Buscar producto...',
                labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 15 // Color del label cuando no está enfocado
                    ),
                floatingLabelStyle: TextStyle(
                  color: Colors.grey, // Color del label cuando está enfocado
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 15, // Tamaño del ícono
                ),
                filled: true, // Habilitar fondo
                fillColor: Color.fromRGBO(255, 255, 255, 1), // Fondo gris claro
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  borderSide: BorderSide(
                    color: Color.fromRGBO(
                        200, 200, 200, 1), // Color del borde al enfocar
                    width: 1.0, // Grosor más delgado
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  borderSide: BorderSide(
                    color: Color.fromRGBO(
                        200, 200, 200, 1), // Color del borde normal
                    width: 1.0, // Grosor más delgado
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10, // Reduce la altura del TextField
                  horizontal: 15, // Espaciado horizontal
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProductos.length,
                itemBuilder: (context, index) {
                  final producto = filteredProductos[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: index % 2 == 0
                        ? const Color(0xFFE9F3EF) // verde para impares
                        : const Color(0xFFDBDBDB), // Gris claro para pares
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) =>
                          //         DetalleProductoScreen(producto: producto),
                          //   ),
                          // );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Icono del producto
                            Image.asset(
                              'Assets/images/cigarettes.png',
                              height: 30, // Altura del icono
                            ), // Ruta del icono en assets
                            const SizedBox(width: 25), // Espaciado adicional
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'Precio: \$${producto.precio}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Botón para eliminar producto
                            IconButton(
                              icon: Image.asset(
                                'Assets/images/borrar.png', 
                                height: 24, 
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Eliminar producto'),
                                    content: const Text(
                                        '¿Estás seguro de que deseas eliminar este producto?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          await ProductoProvider()
                                              .eliminarProducto(producto.id!);
                                          _loadProductos(); // Recargar productos
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Botón para editar producto
                            IconButton(
                              icon: Image.asset(
                                'Assets/images/editar.png', 
                                height: 24, 
                              ),
                              onPressed: () async {
                                // await Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => EditarProductoScreen(
                                //       producto: producto,
                                //     ),
                                //   ),
                                // );
                                // _loadProductos(); // Recargar productos al volver
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
