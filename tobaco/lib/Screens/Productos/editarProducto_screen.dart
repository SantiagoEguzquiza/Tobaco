import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Models/Categoria.dart';

class EditarProductoScreen extends StatefulWidget {
  final Producto producto;
  const EditarProductoScreen({super.key, required this.producto});

  @override
  EditarProductoScreenState createState() => EditarProductoScreenState();
}

class EditarProductoScreenState extends State<EditarProductoScreen> {
  late TextEditingController nombreController;
  late TextEditingController cantidadController;
  late TextEditingController precioController;
  late TextEditingController halfController;

  Categoria? categoriaSeleccionada;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.producto.nombre);
    cantidadController =
        TextEditingController(text: widget.producto.cantidad.toString());
    precioController =
        TextEditingController(text: widget.producto.precio.toString());
    halfController =
        TextEditingController(text: widget.producto.half.toString());

    // Cargar categorías al iniciar
    Future.microtask(() {
      Provider.of<CategoriasProvider>(context, listen: false).obtenerCategorias();
    });
  }

  @override
  void dispose() {
    nombreController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Categoria> categorias =
        Provider.of<CategoriasProvider>(context).categorias;

    
    if (categoriaSeleccionada == null && categorias.isNotEmpty) {
      categoriaSeleccionada = categorias.firstWhere(
        (cat) => cat.nombre == widget.producto.categoriaNombre,
        orElse: () => categorias.first,
      );
    } else if (categoriaSeleccionada != null && categorias.isNotEmpty) {
      
      final match = categorias.where((cat) => cat.id == categoriaSeleccionada!.id).toList();
      if (match.isNotEmpty) {
        categoriaSeleccionada = match.first;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true, // Ajusta la pantalla al teclado
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nombreController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.producto.nombre = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cantidad:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cantidadController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.producto.cantidad =
                            int.tryParse(value)?.toDouble() ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Precio:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: precioController,
                    style: AppTheme.inputTextStyle,
                    cursorColor: Colors.black,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration,
                    onChanged: (value) {
                      setState(() {
                        widget.producto.precio = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categoria:',
                    style: AppTheme.inputLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Categoria>(
                    value: categoriaSeleccionada,
                    isExpanded: true,
                    items: categorias.map((Categoria categoria) {
                      return DropdownMenuItem<Categoria>(
                        value: categoria,
                        child: Text(
                          categoria.nombre,
                          style: AppTheme.inputTextStyle,
                        ),
                      );
                    }).toList(),
                    onChanged: (Categoria? nuevaCategoria) {
                      if (nuevaCategoria != null) {
                        setState(() {
                          categoriaSeleccionada = nuevaCategoria;
                          widget.producto.categoriaId = nuevaCategoria.id!;
                          widget.producto.categoriaNombre = nuevaCategoria.nombre;
                        });
                      }
                    },
                    decoration: AppTheme.inputDecoration.copyWith(
                      hintText: categoriaSeleccionada?.nombre ??
                          'Selecciona una categoría',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        '¿Se puede vender medio?',
                        style: AppTheme.inputLabelStyle,
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: halfController.text == 'true',
                        onChanged: (bool? value) {
                          setState(() {
                            halfController.text =
                                value == true ? 'true' : 'false';
                            widget.producto.half = value == true;
                          });
                        },
                        shape: AppTheme.checkboxTheme.shape,
                        fillColor: AppTheme.checkboxTheme.fillColor,
                        checkColor:
                            AppTheme.checkboxTheme.checkColor?.resolve({}),
                        side: AppTheme.checkboxTheme.side,
                      ),
                    ],
                  ),
                  const SizedBox(height: 80), // Espacio para los botones
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: AppTheme.elevatedButtonStyle(
                          AppTheme.confirmButtonColor,
                        ),
                        onPressed: () async {
                          try {
                            await ProductoProvider()
                                .editarProducto(widget.producto);

                            if (!mounted) return;
                            Navigator.of(context).pop();

                            // Acción para confirmar los cambios
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cambios confirmados'),
                                ),
                              );
                            }
                          } catch (e) {
                            // Manejo de errores
                            debugPrint(
                                'Error al editar el producto: $e'); // Registro del error
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: ${e.toString()}')),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Confirmar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
