import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';

class NuevoProductoScreen extends StatelessWidget {
  const NuevoProductoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controladores para los campos de texto
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController();
    final precioController = TextEditingController();
    final categoriaController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nuevo Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nombre:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese el nombre del producto...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cantidad:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cantidadController,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese la cantidad...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Precio:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: precioController,
              keyboardType: TextInputType.number,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese el precio...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
             const SizedBox(height: 16),
            const Text(
              'Categoria:',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Categoria>(
              value: Categoria.nacional, // Valor inicial
              items: Categoria.values.map((Categoria categoria) {
              return DropdownMenuItem<Categoria>(
                value: categoria,
                child: Text(categoria.name), // Muestra el nombre del enum
              );
              }).toList(),
              onChanged: (Categoria? newValue) {
              categoriaController.text = newValue?.name ?? '';
              },
              decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Seleccione una categoría...',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              ),
            ),
            
            const Spacer(),
            SizedBox(
              width: double.infinity, // Botón ocupa todo el ancho
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Regresa a la pantalla anterior
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color.fromARGB(255, 255, 141, 141),
                  elevation: 5,
                  shadowColor: Colors.black,
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, // Botón ocupa todo el ancho
              child: ElevatedButton(
                onPressed: () async {
                  // Datos del producto
                  final Producto producto = Producto(
                    id: null, // ID se asignará automáticamente en el servidor
                    nombre: nombreController.text,
                    cantidad: double.tryParse(cantidadController.text),
                    precio: double.tryParse(precioController.text) ?? 0.0,
                    categoria: Categoria.values.firstWhere(
                      (categoria) => categoria.name == categoriaController.text,
                      orElse: () => Categoria.nacional, // Valor predeterminado
                    ), // Cambia según tu lógica
                  );

                  try {
                    // Llama al método para guardar el producto
                    await Provider.of<ProductoProvider>(context, listen: false)
                        .crearProducto(producto);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Producto guardado con éxito')),
                    );

                    // Regresa a la pantalla anterior
                    Navigator.pop(context);
                  } catch (e) {
                    // Muestra un mensaje de error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFAAEDAA),
                  elevation: 5,
                  shadowColor: Colors.black,
                ),
                child: const Text(
                  'Guardar',
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
