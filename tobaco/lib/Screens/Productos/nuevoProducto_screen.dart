import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart'; // Importa el tema

class NuevoProductoScreen extends StatelessWidget {
  const NuevoProductoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController();
    final precioController = TextEditingController();
    final categoriaController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nuevo Producto'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Scroll con campos
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 140), // espacio para botones
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre:', style: AppTheme.inputLabelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nombreController,
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Ingrese el nombre...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Cantidad:', style: AppTheme.inputLabelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: cantidadController,
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Ingrese la cantidad...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Precio:', style: AppTheme.inputLabelStyle),
                        const SizedBox(height: 10),
                        TextField(
                          controller: precioController,
                          keyboardType: TextInputType.number,
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Ingrese el precio...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Categoría:',
                            style: AppTheme.inputLabelStyle),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Categoria>(
                          value: Categoria.nacional,
                          items: Categoria.values.map((categoria) {
                            return DropdownMenuItem<Categoria>(
                              value: categoria,
                              child: Text(categoria.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            categoriaController.text = value?.name ?? '';
                          },
                          decoration: AppTheme.inputDecoration.copyWith(
                            hintText: 'Seleccione una categoría...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),

              // Botones fijos al fondo de la pantalla
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: AppTheme.outlinedButtonStyle,
                            child: const Text(
                              'Cancelar',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final producto = Producto(
                                id: null,
                                nombre: nombreController.text,
                                cantidad:
                                    double.tryParse(cantidadController.text),
                                precio:
                                    double.tryParse(precioController.text) ??
                                        0.0,
                                categoria: Categoria.values.firstWhere(
                                  (c) => c.name == categoriaController.text,
                                  orElse: () => Categoria.nacional,
                                ),
                              );

                              try {
                                await Provider.of<ProductoProvider>(context,
                                        listen: false)
                                    .crearProducto(producto);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Producto guardado con éxito')),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            style: AppTheme.elevatedButtonStyle(
                              AppTheme.primaryColor,
                            ),
                            child: const Text(
                              'Guardar',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
